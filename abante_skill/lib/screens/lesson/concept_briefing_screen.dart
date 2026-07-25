import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/editor_dot.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/progress_dots.dart';
import 'ide_workspace_screen.dart';

class _TheoryCard {
  const _TheoryCard({required this.heading, required this.analogy, required this.snippet});

  final String heading;
  final String analogy;
  final String snippet;
}

const _cards = [
  _TheoryCard(
    heading: 'Think of it like a light switch',
    analogy:
        "An if statement checks a condition and only runs code when it's true — just like a switch only turns "
        'the light on when it\'s flipped up.',
    snippet: 'if age >= 18:\n    print("You can vote!")',
  ),
  _TheoryCard(
    heading: 'Add an alternative with else',
    analogy: 'When the condition is false, else gives your program a fallback path to take instead.',
    snippet: 'if age >= 18:\n    print("You can vote!")\nelse:\n    print("Not yet!")',
  ),
  _TheoryCard(
    heading: 'Chain more checks with elif',
    analogy: 'Need more than two outcomes? elif lets you test additional conditions in order.',
    snippet: 'if score >= 90:\n    grade = "A"\nelif score >= 80:\n    grade = "B"\nelse:\n    grade = "C"',
  ),
];

class ConceptBriefingScreen extends StatefulWidget {
  const ConceptBriefingScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<ConceptBriefingScreen> createState() => _ConceptBriefingScreenState();
}

class _ConceptBriefingScreenState extends State<ConceptBriefingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  bool get _isLastCard => _pageIndex == _cards.length - 1;

  void _onNext() {
    if (_isLastCard) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => IdeWorkspaceScreen(lesson: widget.lesson)),
      );
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.lesson.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ProgressDots(count: _cards.length, currentIndex: _pageIndex),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _cards.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) => _TheoryCardView(card: _cards[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: PressableScale(
                child: FilledButton(
                  onPressed: _onNext,
                  child: Text(_isLastCard ? 'Start Coding' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheoryCardView extends StatelessWidget {
  const _TheoryCardView({required this.card});

  final _TheoryCard card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.heading,
            style: AppTheme.headline(fontSize: 24, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(
            card.analogy,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 10)),
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
                        'python',
                        style: AppTheme.code(fontSize: 11, color: AppColors.inkTextDim, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Text(
                    card.snippet,
                    style: AppTheme.code(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
