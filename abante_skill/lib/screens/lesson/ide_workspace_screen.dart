import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../models/practice_language.dart';
import '../../services/ai_code_runner_service.dart';
import '../../services/ai_tutor_service.dart';
import '../../services/curriculum_repository.dart';
import '../../services/hearts_repository.dart';
import '../../services/lesson_exercise_service.dart';
import '../../services/streak_repository.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badges.dart';
import '../../widgets/editor_dot.dart';
import '../../widgets/pressable_scale.dart';
import '../main_shell.dart';
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
  late final _codeController = TextEditingController(
    text: widget.isSandbox ? _language.starterCode : '',
  );
  int _hearts = HeartsRepository.hearts;
  bool _consoleVisible = false;
  bool _isRunning = false;
  bool _runFailed = false;
  bool _lastRunSucceeded = false;
  String _output = '';
  bool _isLoadingExercise = false;
  LessonExercise? _exercise;
  final _sessionStopwatch = Stopwatch()..start();

  String get _instruction => widget.isSandbox ? _sandboxInstruction : (_exercise?.instruction ?? '');
  String get _taskLanguageLabel => _exercise?.language ?? 'python';
  String get _taskFileName => _exercise?.fileName ?? 'main.py';

  @override
  void initState() {
    super.initState();
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
    _recordSessionTime();
    super.dispose();
  }

  void _recordSessionTime() {
    _sessionStopwatch.stop();
    final minutes = (_sessionStopwatch.elapsed.inSeconds / 60).round();
    final user = FirebaseAuth.instance.currentUser;
    if (minutes <= 0 || user == null) return;
    unawaited(StreakRepository.addMinutes(user, minutes));
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
      if (!widget.isSandbox && !success && user != null) {
        await HeartsRepository.loseHeart(user);
      }
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _output = result.output.trim().isEmpty ? '(no output)' : result.output.trim();
        _lastRunSucceeded = success;
        if (!widget.isSandbox && !success) _hearts = HeartsRepository.hearts;
      });

      if (widget.isSandbox) return;

      if (success) {
        _saveLessonProgress();
        showLessonSuccessDialog(
          context,
          onContinue: () {
            // Clears the whole lesson flow (overview sheet, briefing, this
            // screen, and this dialog) in one shot and lands on a fresh
            // Dashboard — robust regardless of how deep the stack got,
            // unlike counting a fixed number of pops.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
          },
        );
      } else if (_hearts == 0) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OutOfHeartsScreen(nextHeartIn: HeartsRepository.timeUntilNextHeart()),
            ),
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

  Future<void> _saveLessonProgress() async {
    final lesson = widget.lesson;
    final user = FirebaseAuth.instance.currentUser;
    if (lesson == null || user == null) return;

    if (!CurriculumRepository.markLessonCompleted(lesson.id)) return;
    try {
      await UserRepository.saveUser(user: user, curriculum: CurriculumRepository.units);
      await UserRepository.addXp(user, lesson.totalModules * 10);
    } catch (_) {
      // Local progress already updated; a sync hiccup shouldn't block the UI.
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isSandbox,
        leading: widget.isSandbox
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                ),
              ),
        title: Text(widget.isSandbox ? 'Sandbox' : widget.lesson!.title),
        centerTitle: true,
        actions: [
          if (!widget.isSandbox)
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
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 140),
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _instruction,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4, fontWeight: FontWeight.w600),
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
                    BoxShadow(color: AppColors.ink.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const EditorDot(color: AppColors.error),
                          const SizedBox(width: 6),
                          const EditorDot(color: AppColors.streak),
                          const SizedBox(width: 6),
                          const EditorDot(color: AppColors.success),
                          const Spacer(),
                          if (widget.isSandbox)
                            _LanguagePicker(language: _language, onChanged: _onLanguageChanged)
                          else
                            Text(
                              _taskFileName,
                              style: AppTheme.code(fontSize: 11, color: AppColors.inkTextDim, weight: FontWeight.w600),
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
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: Colors.white,
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
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: _consoleVisible
                  ? _ConsolePanel(
                      sandbox: widget.isSandbox,
                      isRunning: _isRunning,
                      runFailed: _runFailed,
                      success: _lastRunSucceeded,
                      hearts: _hearts,
                      output: _output,
                      onRetry: _onRunCode,
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
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        ),
      ),
    );
  }
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'AI Tutor Hint',
                style: AppTheme.headline(fontSize: 18, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContent(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _HintState.loading:
        return const Padding(
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
            const Expanded(
              child: Text(
                "Couldn't reach the AI tutor right now.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        );
      case _HintState.loaded:
        return Text(
          _hint,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
        );
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
                if (lang == language) const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
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
          const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.inkTextDim),
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
  });

  final bool sandbox;
  final bool isRunning;
  final bool runFailed;
  final bool success;
  final int hearts;
  final String output;
  final VoidCallback onRetry;

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
        child: const Row(
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
            const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            const Expanded(
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
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8)),
        ],
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
                      sandbox ? 'Ran without errors' : (success ? 'Nice work — that looks correct!' : "That didn't quite work"),
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
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 140),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
            child: SingleChildScrollView(
              child: Text(
                output,
                style: AppTheme.code(fontSize: 12, color: AppColors.inkTextDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
