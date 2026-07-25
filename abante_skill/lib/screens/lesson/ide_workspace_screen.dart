import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badges.dart';
import '../../widgets/editor_dot.dart';
import '../../widgets/pressable_scale.dart';
import '../main_shell.dart';
import 'lesson_success_dialog.dart';
import 'out_of_hearts_screen.dart';

const _sandboxInstruction =
    'Free practice — write any Python code you like and hit Run. No hearts, no pressure.';
const _taskInstruction = 'Create a variable named age, set it to 20, then write an '
    'if / else statement that prints "You can vote!" when age is 18 or older.';

const _sandboxStarterCode = '# Sandbox — experiment freely\n\nprint("Hello, world!")\n';
const _taskStarterCode = '# Write your code below\n\n';

class IdeWorkspaceScreen extends StatefulWidget {
  const IdeWorkspaceScreen({super.key, required this.lesson});

  /// The active lesson task, or `null` for free-form sandbox practice.
  final Lesson? lesson;

  bool get isSandbox => lesson == null;

  @override
  State<IdeWorkspaceScreen> createState() => _IdeWorkspaceScreenState();
}

class _IdeWorkspaceScreenState extends State<IdeWorkspaceScreen> {
  late final _codeController = TextEditingController(
    text: widget.isSandbox ? _sandboxStarterCode : _taskStarterCode,
  );
  int _hearts = 3;
  bool _consoleVisible = false;
  bool _lastRunSucceeded = false;

  String get _instruction => widget.isSandbox ? _sandboxInstruction : _taskInstruction;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _looksCorrect {
    final code = _codeController.text.toLowerCase();
    return code.contains('if') && code.contains('18') && code.contains('age');
  }

  void _onRunCode() {
    if (widget.isSandbox) {
      setState(() => _consoleVisible = true);
      return;
    }

    final success = _looksCorrect;
    setState(() {
      _consoleVisible = true;
      _lastRunSucceeded = success;
      if (!success) _hearts = (_hearts - 1).clamp(0, 3);
    });

    if (success) {
      showLessonSuccessDialog(
        context,
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    } else if (_hearts == 0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OutOfHeartsScreen()),
        );
      });
    }
  }

  void _onAskAiTutor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
            const SizedBox(height: 14),
            Text(
              widget.isSandbox
                  ? "Nothing to check here — try a for loop, define a function, or just print things out. "
                      "It's your playground."
                  : 'Start by creating a variable: age = 20. Then use if age >= 18: on one line, and put your '
                      'print(...) statement indented on the next line.',
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
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
        child: Column(
          children: [
            Container(
              width: double.infinity,
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
                    child: Text(
                      _instruction,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4, fontWeight: FontWeight.w600),
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
                          Text(
                            widget.isSandbox ? 'sandbox.py' : 'main.py',
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
                          decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
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
                  ? _ConsolePanel(sandbox: widget.isSandbox, success: _lastRunSucceeded, hearts: _hearts)
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
                        onPressed: _onRunCode,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Run Code'),
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

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({required this.sandbox, required this.success, required this.hearts});

  final bool sandbox;
  final bool success;
  final int hearts;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(effectiveSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sandbox ? 'Ran without errors' : (success ? 'Nice work — that runs correctly!' : "That didn't quite work"),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  sandbox
                      ? 'This is a sandbox — output is not graded.'
                      : success
                          ? 'Your if / else statement correctly checks the age variable.'
                          : hearts == 0
                              ? "You're out of hearts — heading back to review."
                              : 'Make sure you created a variable named age set to 20, and used an if statement '
                                  'checking age >= 18.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
