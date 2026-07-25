import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_dots.dart';
import '../../widgets/selectable_option_card.dart';
import '../auth/signup_screen.dart';

class _Question {
  const _Question({required this.title, required this.subtitle, required this.options});

  final String title;
  final String subtitle;
  final List<_Option> options;
}

class _Option {
  const _Option({required this.title, this.subtitle, required this.icon});

  final String title;
  final String? subtitle;
  final IconData icon;
}

const _questions = [
  _Question(
    title: 'What do you want to learn?',
    subtitle: "Pick the track you're most excited about.",
    options: [
      _Option(title: 'Python', subtitle: 'Great for beginners', icon: Icons.data_object_rounded),
      _Option(title: 'Web Development', subtitle: 'HTML, CSS & JS', icon: Icons.public_rounded),
      _Option(title: 'JavaScript', subtitle: 'Build interactive apps', icon: Icons.bolt_rounded),
      _Option(title: 'Data Science', subtitle: 'Work with data & AI', icon: Icons.insights_rounded),
    ],
  ),
  _Question(
    title: "What's your experience level?",
    subtitle: "We'll tailor lessons to match you.",
    options: [
      _Option(title: 'Beginner', subtitle: 'New to coding', icon: Icons.eco_rounded),
      _Option(title: 'Intermediate', subtitle: 'Know the basics', icon: Icons.auto_graph_rounded),
      _Option(title: 'Pro', subtitle: 'Comfortable building projects', icon: Icons.workspace_premium_rounded),
    ],
  ),
  _Question(
    title: "What's your daily goal?",
    subtitle: 'Small, consistent habits win.',
    options: [
      _Option(title: '5 minutes / day', subtitle: 'Casual', icon: Icons.timer_outlined),
      _Option(title: '15 minutes / day', subtitle: 'Serious', icon: Icons.timer_rounded),
    ],
  ),
];

class OnboardingQuestionnaireScreen extends StatefulWidget {
  const OnboardingQuestionnaireScreen({super.key});

  @override
  State<OnboardingQuestionnaireScreen> createState() => _OnboardingQuestionnaireScreenState();
}

class _OnboardingQuestionnaireScreenState extends State<OnboardingQuestionnaireScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;
  final List<int?> _answers = List.filled(_questions.length, null);

  bool get _isLastPage => _pageIndex == _questions.length - 1;
  bool get _canContinue => _answers[_pageIndex] != null;

  void _onContinue() {
    if (!_canContinue) return;
    if (_isLastPage) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignupScreen()),
      );
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _onBack() {
    if (_pageIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _onBack,
        ),
        title: ProgressDots(count: _questions.length, currentIndex: _pageIndex),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.title,
                          style: AppTheme.headline(fontSize: 26, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.subtitle,
                          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            itemCount: question.options.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, optionIndex) {
                              final option = question.options[optionIndex];
                              return SelectableOptionCard(
                                title: option.title,
                                subtitle: option.subtitle,
                                icon: option.icon,
                                selected: _answers[index] == optionIndex,
                                onTap: () => setState(() => _answers[index] = optionIndex),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: FilledButton(
                onPressed: _canContinue ? _onContinue : null,
                child: Text(_isLastPage ? 'Continue' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
