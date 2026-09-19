import 'package:flutter/material.dart';

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
      icon: Icons.search,
    ),
    OnboardingItem(
      title: 'Entenda antes de escolher',
      description:
          'Consulte informações alimentares e conheça '
          'melhor as opções disponíveis.',
      icon: Icons.fact_check_outlined,
    ),
    OnboardingItem(
      title: 'Uma experiência mais relevante',
      description:
          'Seu perfil alimentar poderá ajudar o CeliLac '
          'a apresentar opções mais adequadas.',
      icon: Icons.person_outline,
    ),
  ];

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _nextPage() async {
    if (_currentPage < OnboardingPage.items.length - 1) {
      await _controller.nextPage(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemCount: OnboardingPage.items.length,
        itemBuilder: (context, index) {
          return _OnboardingContent(item: OnboardingPage.items[index]);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _nextPage,
            child: Text(
              _currentPage < OnboardingPage.items.length - 1
                  ? 'Próximo'
                  : 'Começar',
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 96),
          const SizedBox(height: 32),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
