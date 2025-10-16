import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../consent/consent_history_screen.dart';
import '../events/event_crud_screen.dart';
import 'marketing_consent_page.dart';
import 'consentimento_resumo_page.dart';
import 'leitura_md_page.dart';
import '../home/home_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  bool _politicaLida = false;
  bool _termosLidos = false;

  void _irParaPolitica() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LeituraMdPage(
        titulo: 'Política de Privacidade',
        assetPath: 'privacidade.md',
        onLeuTudo: () {
          setState(() => _politicaLida = true);
          Navigator.of(context).pop();
        },
      ),
    ));
  }

  void _irParaTermos() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LeituraMdPage(
        titulo: 'Termos de Uso',
        assetPath: 'termos.md',
        onLeuTudo: () {
          setState(() => _termosLidos = true);
          Navigator.of(context).pop();
        },
      ),
    ));
  }

  void _avancarConsentimento() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool('consent_accepted', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      // Centraliza o botão de avançar na tela de boas-vindas
      Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('PNGs/logoIASemfundo.png', width: 120, height: 120),
                  const SizedBox(height: 24),
                  Text(
                    'Bem-vindo!',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Organize mini-eventos gamers com facilidade.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _currentPage++;
                  });
                },
                child: const Text('Avançar'),
              ),
            ),
          ),
        ],
      ),
      Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: cyan, size: 80),
              const SizedBox(height: 24),
              Text(
                'O que é o Gamer Event Platform?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Crie eventos, marque tarefas e acompanhe o progresso do seu mini-evento gamer com checklist e horários!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: cyan, size: 80),
              const SizedBox(height: 24),
              Text(
                'Tudo pronto!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vamos começar a organizar seu evento gamer!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      MarketingConsentPage(
        onContinue: () {
          setState(() => _currentPage = 4);
        },
      ),
      ConsentimentoResumoPage(
        onLerPolitica: _irParaPolitica,
        onLerTermos: _irParaTermos,
        onAvancar: _avancarConsentimento,
        politicaLida: _politicaLida,
        termosLidos: _termosLidos,
      ),
    ];

    return Scaffold(
      backgroundColor: slate,
      body: pages[_currentPage],
      bottomNavigationBar: (_currentPage > 0 && _currentPage < 3)
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slate,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 40),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                      child: const Text('Voltar'),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentPage++;
                      });
                    },
                    child: const Text('Avançar'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}