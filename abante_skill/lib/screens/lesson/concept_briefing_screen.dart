import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../services/curriculum_repository.dart';
import '../../services/groq_client.dart';
import '../../services/lesson_content_service.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/editor_dot.dart';
import '../../widgets/practice_time_tracker.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/progress_dots.dart';
import 'ide_workspace_screen.dart';
import 'lesson_load_states.dart';

class ConceptBriefingScreen extends StatefulWidget {
  const ConceptBriefingScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<ConceptBriefingScreen> createState() => _ConceptBriefingScreenState();
}

class _ConceptBriefingScreenState extends State<ConceptBriefingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;
  bool _isLoading = true;
  bool _loadFailed = false;
  List<TheoryCard> _cards = const [];

  bool get _isLastCard => _pageIndex == _cards.length - 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Reuse the cached cards if this lesson already has them, so reopening
    // the briefing shows the same content instead of new AI-regenerated one.
    final cachedCards = widget.lesson.theoryCards;
    final isLegacyPlaceholder =
        cachedCards != null && cachedCards.isNotEmpty && cachedCards.first['heading'] == legacyPlaceholderCardHeading;
    if (cachedCards != null && cachedCards.isNotEmpty && !isLegacyPlaceholder) {
      setState(() {
        _cards = cachedCards
            .map(
              (c) => TheoryCard(
                heading: c['heading'] ?? '',
                analogy: c['analogy'] ?? '',
                snippet: c['snippet'] ?? '',
                language: c['language'] ?? 'code',
              ),
            )
            .toList();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final List<TheoryCard> cards;
    try {
      cards = await LessonContentService.generate(
        lessonTitle: widget.lesson.title,
        lessonSummary: widget.lesson.summary,
        level: CurriculumRepository.level,
      );
    } on GroqUnavailable {
      // Show a "try again" state — never stand-in content from another
      // topic, and nothing gets saved, so the next try starts fresh.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _pageIndex = 0;
      _isLoading = false;
    });

    CurriculumRepository.cacheTheoryCards(
      widget.lesson.id,
      cards
          .map((c) => {'heading': c.heading, 'analogy': c.analogy, 'snippet': c.snippet, 'language': c.language})
          .toList(),
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

  void _onNext() {
    if (_isLastCard) {
      // A plain push (not pushReplacement) here — replacing this route
      // would complete the Future that showLessonOverviewSheet's caller is
      // awaiting (a replaced route resolves the same as a popped one),
      // which pops the IDE workspace screen the instant it appears.
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => IdeWorkspaceScreen(lesson: widget.lesson)));
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return PracticeTimeTracker(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
          title: Text(widget.lesson.title),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? const LessonLoading(message: 'Writing your lesson…')
              : _loadFailed
              ? LessonLoadError(
                  onRetry: _load,
                  secondaryLabel: 'Skip to coding',
                  onSecondary: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => IdeWorkspaceScreen(lesson: widget.lesson))),
                )
              : Column(
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
                        child: FilledButton(onPressed: _onNext, child: Text(_isLastCard ? 'Start Coding' : 'Next')),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TheoryCardView extends StatelessWidget {
  const _TheoryCardView({required this.card});

  final TheoryCard card;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.heading, style: AppTheme.headline(fontSize: 24, weight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(card.analogy, style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5)),
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
                      EditorDot(color: AppColors.error),
                      const SizedBox(width: 6),
                      EditorDot(color: AppColors.streak),
                      const SizedBox(width: 6),
                      EditorDot(color: AppColors.success),
                      const Spacer(),
                      Text(
                        card.language,
                        style: AppTheme.code(fontSize: 11, color: AppColors.inkTextDim, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Text(card.snippet, style: AppTheme.code()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
