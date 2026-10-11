import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../models/practice_language.dart';
import '../../services/ai_code_runner_service.dart';
import '../../services/ai_tutor_service.dart';
import '../../services/app_settings.dart';
import '../../services/certificate_repository.dart';
import '../../services/curriculum_repository.dart';
import '../../services/hearts_repository.dart';
import '../../services/lesson_exercise_service.dart';
import '../../services/session_service.dart';
import '../../services/streak_repository.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badges.dart';
import '../../widgets/editor_dot.dart';
import '../../widgets/pressable_scale.dart';
import '../main_shell.dart';
import 'certificate_dialog.dart';
import 'lesson_success_dialog.dart';
import 'out_of_hearts_screen.dart';

const _sandboxInstruction =
    'Free practice — pick a language, write any code you like, and hit Run. No hearts, no pressure.';

class IdeWorkspaceScreen extends StatefulWidget {
  const IdeWorkspaceScreen({super.key, required this.lesson});

  /// The active lesson task, or `null` for free-form sandbox practice.
  final Lesson? lesson;

  bool get isSandbox => lesson == null;

  @override
  State<IdeWorkspaceScreen> createState() => _IdeWorkspaceScreenState();
}

class _IdeWorkspaceScreenState extends State<IdeWorkspaceScreen> {
  PracticeLanguage _language = PracticeLanguage.python;
  late final _codeController = TextEditingController(text: widget.isSandbox ? _language.starterCode : '');

  /// While the editor has focus (i.e. the on-screen keyboard is up), the
  /// screen switches to a compact "writing" layout so the keyboard doesn't
  /// squeeze the editor down to nothing.
  final _codeFocus = FocusNode();
  bool get _isEditing => _codeFocus.hasFocus;
  int _hearts = HeartsRepository.hearts;
  bool _consoleVisible = false;
  bool _isRunning = false;
  bool _runFailed = false;
  bool _lastRunSucceeded = false;
  String _output = '';
  bool _isLoadingExercise = false;
  LessonExercise? _exercise;
  final _sessionStopwatch = Stopwatch()..start();

  /// Replaying an already-finished lesson: no hearts at stake, no repeat
  /// XP, and passing earns a heart back.
  late final bool _isReview = !widget.isSandbox && CurriculumRepository.isCompleted(widget.lesson!.id);

  String get _instruction => widget.isSandbox ? _sandboxInstruction : (_exercise?.instruction ?? '');
  String get _taskLanguageLabel => _exercise?.language ?? 'python';
  String get _taskFileName => _exercise?.fileName ?? 'main.py';

  @override
  void initState() {
    super.initState();
    _codeFocus.addListener(_onFocusChanged);
    if (!widget.isSandbox) {
      _loadExercise();
      _loadHearts();
    }
  }

  Future<void> _loadHearts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await HeartsRepository.load(user);
    if (!mounted) return;
    setState(() => _hearts = HeartsRepository.hearts);
  }

  Future<void> _loadExercise() async {
    final lesson = widget.lesson!;

    // Reuse the cached exercise if this lesson already has one, so
    // reopening it shows the same exercise instead of a new random one.
    if (lesson.hasCachedExercise) {
      final exercise = LessonExercise(
        instruction: lesson.exerciseInstruction!,
        starterCode: lesson.exerciseStarterCode ?? '',
        language: lesson.exerciseLanguage ?? 'python',
        fileName: lesson.exerciseFileName ?? 'main.py',
      );
      setState(() {
        _exercise = exercise;
        _codeController.text = exercise.starterCode;
        _isLoadingExercise = false;
      });
      return;
    }

    setState(() => _isLoadingExercise = true);
    final exercise = await LessonExerciseService.generate(
      lessonTitle: lesson.title,
      lessonSummary: lesson.summary,
      level: CurriculumRepository.level,
    );
    if (!mounted) return;
    setState(() {
      _exercise = exercise;
      _codeController.text = exercise.starterCode;
      _isLoadingExercise = false;
    });

    CurriculumRepository.cacheExercise(
      lesson.id,
      instruction: exercise.instruction,
      starterCode: exercise.starterCode,
      language: exercise.language,
      fileName: exercise.fileName,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await UserRepository.saveUser(user: user, curriculum: CurriculumRepository.units);
      } catch (_) {
        // Local cache already updated; a sync hiccup shouldn't block the UI.
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _recordSessionTime();
    super.dispose();
  }

  void _recordSessionTime() {
    _sessionStopwatch.stop();
    final minutes = (_sessionStopwatch.elapsed.inSeconds / 60).round();
    if (minutes <= 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    unawaited(StreakRepository.addMinutes(user, minutes));
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Inserts [text] at the cursor (replacing any selection) — used by the
  /// quick-symbol keys above the keyboard.
  void _insertText(String text) {
    final value = _codeController.value;
    final selection = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
    _codeController.value = TextEditingValue(
      text: value.text.replaceRange(selection.start, selection.end, text),
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _runFromKeyboard() {
    _codeFocus.unfocus();
    _onRunCode();
  }

  void _showFullTask() {
    _codeFocus.unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskSheet(instruction: _instruction),
    );
  }

  void _onLanguageChanged(PracticeLanguage language) {
    setState(() {
      _language = language;
      _codeController.text = language.starterCode;
      _consoleVisible = false;
    });
  }

  Future<void> _onRunCode() async {
    setState(() {
      _isRunning = true;
      _runFailed = false;
      _consoleVisible = true;
    });

    try {
      final result = await AiCodeRunnerService.run(
        code: _codeController.text,
        language: widget.isSandbox ? _language.label : _taskLanguageLabel,
        taskInstruction: widget.isSandbox ? null : _instruction,
      );

      if (!mounted) return;
      final success = result.correct;
      final user = FirebaseAuth.instance.currentUser;
      if (!widget.isSandbox && !success && !_isReview && user != null) {
        await HeartsRepository.loseHeart(user);
      }
      if (!widget.isSandbox) unawaited(success ? Sfx.correct() : Sfx.wrong());
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _output = result.output.trim().isEmpty ? '(no output)' : result.output.trim();
        _lastRunSucceeded = success;
        if (!widget.isSandbox && !success && !_isReview) _hearts = HeartsRepository.hearts;
      });

      if (widget.isSandbox) return;

      if (success) {
        final outcome = await _saveLessonProgress();
        if (!mounted) return;
        setState(() => _hearts = HeartsRepository.hearts);
        SessionService.requestRefresh();
        final earnedCertificate = outcome.certificate;
        showLessonSuccessDialog(
          context,
          xpEarned: outcome.xp,
          isReview: _isReview,
          heartRestored: outcome.heartRestored,
          onContinue: () async {
            if (earnedCertificate != null) {
              unawaited(Sfx.celebrate());
              final user = FirebaseAuth.instance.currentUser;
              final displayName = user?.displayName?.trim().isNotEmpty == true
                  ? user!.displayName!.trim()
                  : (user?.email?.split('@').first ?? 'there');
              await showCertificateDialog(
                context,
                unitTitle: earnedCertificate.unitTitle,
                userName: displayName,
                earnedAt: earnedCertificate.earnedAt,
              );
              if (!mounted) return;
            }
            // Clears the whole lesson flow (overview sheet, briefing, this
            // screen, and this dialog) in one shot and lands on a fresh
            // Dashboard — robust regardless of how deep the stack got,
            // unlike counting a fixed number of pops.
            Navigator.of(
              context,
            ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
          },
        );
      } else if (_hearts == 0 && !_isReview) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => OutOfHeartsScreen(nextHeartIn: HeartsRepository.timeUntilNextHeart())),
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _runFailed = true;
      });
    }
  }

  Future<_LessonOutcome> _saveLessonProgress() async {
    final lesson = widget.lesson;
    final user = FirebaseAuth.instance.currentUser;
    if (lesson == null || user == null) return const _LessonOutcome();

    // Reviews pay out a heart instead of XP, so replaying a finished lesson
    // can't farm XP or inflate the lessons-completed count.
    if (_isReview) {
      final hadRoom = HeartsRepository.hearts < HeartsRepository.maxHearts;
      await HeartsRepository.gainHeart(user);
      return _LessonOutcome(heartRestored: hadRoom);
    }

    if (!CurriculumRepository.markLessonCompleted(lesson.id)) return const _LessonOutcome();
    final xp = lesson.totalModules * 10;
    try {
      await UserRepository.saveUser(user: user, curriculum: CurriculumRepository.units);
      await UserRepository.recordLessonCompleted(user, xp);
    } catch (_) {
      // Local progress already updated; a sync hiccup shouldn't block the UI.
    }

    for (final unit in CurriculumRepository.units) {
      if (unit.lessons.any((l) => l.id == lesson.id)) {
        return _LessonOutcome(xp: xp, certificate: await CertificateRepository.awardIfUnitComplete(user, unit));
      }
    }
    return _LessonOutcome(xp: xp);
  }

  void _onAskAiTutor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AiTutorSheet(
        instruction: widget.isSandbox ? 'Free sandbox practice — no fixed goal.' : _instruction,
        code: _codeController.text,
        language: widget.isSandbox ? _language.label : _taskLanguageLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _isEditing;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isSandbox,
        leading: widget.isSandbox
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(
                  context,
                ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false),
              ),
        title: Text(
          widget.isSandbox ? 'Sandbox' : (_isReview ? 'Review · ${widget.lesson!.title}' : widget.lesson!.title),
        ),
        centerTitle: true,
        actions: [
          if (!widget.isSandbox && !_isReview)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: HeartsBadge(hearts: _hearts)),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingExercise
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (editing)
                    _CompactTaskBar(instruction: _instruction, onTap: _showFullTask)
                  else
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 120),
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _instruction,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: [
                                EditorDot(color: AppColors.error),
                                const SizedBox(width: 6),
                                EditorDot(color: AppColors.streak),
                                const SizedBox(width: 6),
                                EditorDot(color: AppColors.success),
                                const Spacer(),
                                if (widget.isSandbox)
                                  _LanguagePicker(language: _language, onChanged: _onLanguageChanged)
                                else
                                  Text(
                                    _taskFileName,
                                    style: AppTheme.code(
                                      fontSize: 11,
                                      color: AppColors.inkTextDim,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                              child: TextField(
                                controller: _codeController,
                                focusNode: _codeFocus,
                                keyboardType: TextInputType.multiline,
                                autocorrect: false,
                                enableSuggestions: false,
                                smartQuotesType: SmartQuotesType.disabled,
                                smartDashesType: SmartDashesType.disabled,
                                textCapitalization: TextCapitalization.none,
                                scrollPadding: const EdgeInsets.only(bottom: 80),
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                cursorColor: AppColors.inkText,
                                style: AppTheme.code(),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  filled: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (editing)
                    _CodeKeysBar(
                      onInsert: _insertText,
                      onDone: _codeFocus.unfocus,
                      onRun: _isRunning ? null : _runFromKeyboard,
                    )
                  else ...[
                    AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: _consoleVisible
                          ? _ConsolePanel(
                              sandbox: widget.isSandbox,
                              isRunning: _isRunning,
                              runFailed: _runFailed,
                              success: _lastRunSucceeded,
                              hearts: _isReview ? 1 : _hearts,
                              output: _output,
                              onRetry: _onRunCode,
                              onClose: () => setState(() => _consoleVisible = false),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: PressableScale(
                              child: OutlinedButton.icon(
                                onPressed: _onAskAiTutor,
                                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                                label: const Text('Ask AI Tutor'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PressableScale(
                              child: FilledButton.icon(
                                onPressed: _isRunning ? null : _onRunCode,
                                icon: _isRunning
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                                      )
                                    : const Icon(Icons.play_arrow_rounded, size: 20),
                                label: Text(_isRunning ? 'Running...' : 'Run Code'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// One-line version of the task shown while typing; tap to read it all.
class _CompactTaskBar extends StatelessWidget {
  const _CompactTaskBar({required this.instruction, required this.onTap});

  final String instruction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          canRequestFocus: false,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instruction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'View',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The full task text in a sheet, opened from [_CompactTaskBar].
class _TaskSheet extends StatelessWidget {
  const _TaskSheet({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('Your task', style: AppTheme.headline(fontSize: 18, weight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Text(instruction, style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to coding')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim toolbar that sits right above the keyboard while typing: hide the
/// keyboard, quick keys for symbols that are fiddly on phone keyboards, and
/// Run.
class _CodeKeysBar extends StatelessWidget {
  const _CodeKeysBar({required this.onInsert, required this.onDone, required this.onRun});

  final ValueChanged<String> onInsert;
  final VoidCallback onDone;
  final VoidCallback? onRun;

  static const _keys = [
    ('Tab', '    '),
    ('(', '('),
    (')', ')'),
    ('{', '{'),
    ('}', '}'),
    ('[', '['),
    (']', ']'),
    (':', ':'),
    (';', ';'),
    ('=', '='),
    ('"', '"'),
    ("'", "'"),
    ('<', '<'),
    ('>', '>'),
    ('_', '_'),
    ('#', '#'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _BarButton(
            onTap: onDone,
            child: Icon(Icons.keyboard_hide_rounded, size: 20, color: AppColors.textSecondary),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              itemCount: _keys.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final (label, text) = _keys[i];
                return Material(
                  color: AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    canRequestFocus: false,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onInsert(text),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 34),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: AppTheme.code(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
            child: Material(
              color: onRun == null ? AppColors.border : AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                canRequestFocus: false,
                borderRadius: BorderRadius.circular(10),
                onTap: onRun,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Run',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      canRequestFocus: false,
      onTap: onTap,
      child: SizedBox(width: 48, height: 48, child: Center(child: child)),
    );
  }
}

class _LessonOutcome {
  const _LessonOutcome({this.xp = 0, this.certificate, this.heartRestored = false});

  final int xp;
  final EarnedCertificate? certificate;
  final bool heartRestored;
}

enum _HintState { loading, error, loaded }

class _AiTutorSheet extends StatefulWidget {
  const _AiTutorSheet({required this.instruction, required this.code, required this.language});

  final String instruction;
  final String code;
  final String language;

  @override
  State<_AiTutorSheet> createState() => _AiTutorSheetState();
}

class _AiTutorSheetState extends State<_AiTutorSheet> {
  _HintState _state = _HintState.loading;
  String _hint = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _HintState.loading);
    try {
      final hint = await AiTutorService.getHint(
        instruction: widget.instruction,
        code: widget.code,
        language: widget.language,
      );
      if (!mounted) return;
      setState(() {
        _hint = hint;
        _state = _HintState.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _HintState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('AI Tutor Hint', style: AppTheme.headline(fontSize: 18, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          _buildContent(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _HintState.loading:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Thinking...', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        );
      case _HintState.error:
        return Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't reach the AI tutor right now.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        );
      case _HintState.loaded:
        return Text(_hint, style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5));
    }
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.language, required this.onChanged});

  final PracticeLanguage language;
  final ValueChanged<PracticeLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PracticeLanguage>(
      initialValue: language,
      onSelected: onChanged,
      tooltip: 'Change language',
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        for (final lang in PracticeLanguage.values)
          PopupMenuItem(
            value: lang,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lang == language) Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                if (lang == language) const SizedBox(width: 6),
                Text(lang.label),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.fileName,
            style: AppTheme.code(fontSize: 11, color: AppColors.inkTextDim, weight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.inkTextDim),
        ],
      ),
    );
  }
}

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({
    required this.sandbox,
    required this.isRunning,
    required this.runFailed,
    required this.success,
    required this.hearts,
    required this.output,
    required this.onRetry,
    required this.onClose,
  });

  final bool sandbox;
  final bool isRunning;
  final bool runFailed;
  final bool success;
  final int hearts;
  final String output;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('AI is working out the output...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (runFailed) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't reach the AI to run this.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    final effectiveSuccess = sandbox ? true : success;
    final color = effectiveSuccess ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(effectiveSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sandbox
                          ? 'Ran without errors'
                          : (success ? 'Nice work — that looks correct!' : "That didn't quite work"),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sandbox
                          ? 'This is a sandbox — output is not graded.'
                          : success
                          ? 'The AI checked your code against the task and it looks right.'
                          : hearts == 0
                          ? "You're out of hearts — heading back to review."
                          : 'The AI judged this against the task instructions — check the output below and try again.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Hide output',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(backgroundColor: Colors.transparent, padding: EdgeInsets.zero),
                icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 110),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
            child: SingleChildScrollView(
              child: Text(output, style: AppTheme.code(fontSize: 12, color: AppColors.inkTextDim)),
            ),
          ),
        ],
      ),
    );
  }
}
