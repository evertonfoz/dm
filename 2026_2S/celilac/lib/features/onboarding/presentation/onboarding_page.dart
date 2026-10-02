import 'package:celilac/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../app/common/widgets/gold_accent.dart';
import '../../../app/common/widgets/image_card.dart';
import '../../home/presentation/pages/home_page.dart';
import '../data/onboarding_storage.dart';
import '../domain/onboarding_item.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Encontre opções adequadas a você',
      description:
          'Descubra produtos e estabelecimentos '
          'considerando suas necessidades alimentares.',
      imagePath: 'assets/images/onboarding/discovery.png',
    ),
    OnboardingItem(
      title: 'Entenda antes de escolher',
      description:
          'Consulte informações alimentares e conheça '
          'melhor as opções disponíveis.',
      imagePath: 'assets/images/onboarding/information.png',
    ),
    OnboardingItem(
      title: 'Uma experiência mais relevante',
      description:
          'Seu perfil alimentar poderá ajudar o CeliLac '
          'a apresentar opções mais adequadas.',
      imagePath: 'assets/images/onboarding/profile.png',
    ),
  ];

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _introController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _actionFade;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _actionFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < OnboardingPage.items.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final storage = OnboardingStorage();
    await storage.markAsCompleted();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  Widget _buildTopBar() {
    final isLastPage = _currentPage == OnboardingPage.items.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: AnimatedOpacity(
            opacity: isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                'Pular',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FadeTransition(opacity: _actionFade, child: _buildTopBar()),
          Expanded(
            child: FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: OnboardingPage.items.length,
                  itemBuilder: (context, index) {
                    return _OnboardingContent(
                      item: OnboardingPage.items[index],
                    );
                  },
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _actionFade,
            child: _PageIndicator(
              currentPage: _currentPage,
              totalPages: OnboardingPage.items.length,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            // padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _nextPage,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              _currentPage < OnboardingPage.items.length - 1
                  ? 'Próximo'
                  : 'Começar',
              key: ValueKey<int>(_currentPage),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // const Spacer(),
          const SizedBox(height: 32),
          Flexible(
            flex: 6,
            child: AspectRatio(
              aspectRatio: 1,
              child: IllustrationCard(
                imagePath: item.imagePath,
                boxShaddowAlpha: 0.22,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const GoldAccent(),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.navy.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.totalPages});

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold
                : AppColors.navy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
