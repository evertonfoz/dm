import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final int _totalPages = 3;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bem-vindo ao TaskFlow',
      subtitle: 'Benefício central: to-dos com priorização simples',
      description:
          'Organize suas tarefas de forma inteligente com nosso sistema de priorização visual. Foque no que realmente importa.',
      icon: Icons.task_alt,
      color: const Color(0xFF4F46E5), // Indigo primário
    ),
    OnboardingPage(
      title: 'Como Funciona',
      subtitle: 'Gestão de tarefas e foco',
      description:
          'Crie tarefas, defina prioridades, estabeleça prazos e acompanhe seu progresso. Simples assim!',
      icon: Icons.psychology,
      color: const Color(0xFF475569), // Gray secundário
    ),
    OnboardingPage(
      title: 'Pronto para Começar!',
      subtitle: 'Protegemos seus dados com transparência',
      description:
          'Antes de começar, precisamos que você leia e concorde com nossa política de privacidade e termos de uso. Sua privacidade é nossa prioridade.',
      icon: Icons.rocket_launch,
      color: const Color(0xFFF59E0B), // Amber acento
    ),
  ];

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      print('➡️ Avançando para página: $_currentPage');
    } else {
      _navigateToConsent();
    }
  }

  void _previousPage() {
    print('⬅️ PreviousPage chamado: Página atual = $_currentPage');
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      print('🎯 Navegando para página: $_currentPage');
    }
  }

  void _skipOnboarding() {
    _navigateToConsent();
  }

  void _navigateToConsent() {
    Navigator.of(context).pushReplacementNamed('/consent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (oculto na última página conforme RF-1)
            if (_currentPage < _totalPages - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    button: true,
                    hint: 'Pular para o consentimento',
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48), // A11Y target
                      ),
                      child: const Text(
                        'Pular',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 56), // Espaço equivalente ao botão
            // Page content
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    _previousPage();
                  } else if (details.primaryVelocity! < 0) {
                    _nextPage();
                  }
                },
                child: IndexedStack(
                  index: _currentPage,
                  children: [
                    _buildPageContent(0),
                    _buildPageContent(1),
                    _buildPageContent(2),
                  ],
                ),
              ),
            ),

            // Dots indicator (ocultos na última página conforme RF-1)
            if (_currentPage < _totalPages - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: DotsIndicator(
                  dotsCount: _totalPages,
                  position: _currentPage,
                  decorator: DotsDecorator(
                    activeColor: Theme.of(context).primaryColor,
                    color: Colors.grey.shade300,
                    size: const Size.square(8.0),
                    activeSize: const Size(20.0, 8.0),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48), // Espaço equivalente aos dots
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Botão Voltar (sempre mostra o espaço, mas só habilita se não for a primeira página)
                  SizedBox(
                    width: 80,
                    height: 48, // Target mínimo RNF A11Y
                    child: _currentPage > 0
                        ? Semantics(
                            button: true,
                            hint: 'Voltar para a página anterior',
                            child: TextButton(
                              onPressed: _previousPage,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  48,
                                  48,
                                ), // Target mínimo
                              ),
                              child: const Text('Voltar'),
                            ),
                          )
                        : const SizedBox(), // Espaço vazio se for primeira página
                  ),

                  const Spacer(),

                  // Botão Avançar
                  Semantics(
                    button: true,
                    hint: _currentPage == _totalPages - 1
                        ? 'Continuar para as políticas'
                        : 'Avançar para próxima página',
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          48,
                          48,
                        ), // Target mínimo RNF A11Y
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? 'Continuar'
                            : 'Avançar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildPageContent(int index) {
    final page = _pages[index];
    print(
      '🏗️ Construindo página $index: ${page.title} - Ícone: ${page.icon} - Cor: ${page.color}',
    );

    return SizedBox(
      key: ValueKey('page_$index'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: page.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(page.icon, size: 120, color: page.color),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              page.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: page.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              page.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
