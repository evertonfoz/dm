import 'package:celilac/app/common/widgets/image_card.dart';
import 'package:flutter/material.dart';

import '../../../app/common/widgets/gold_accent.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/fade_route.dart';
import '../../../app/shell/app_shell.dart';
import '../../onboarding/data/onboarding_storage.dart';
import '../../onboarding/presentation/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Cores da marca (extraídas do logo e do flutter_native_splash.yaml).
  late final AnimationController _introController;
  late final AnimationController _progressController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _footerFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    await _introController.forward();
    if (!mounted) {
      return;
    }

    await _progressController.forward();
    if (!mounted) {
      return;
    }

    final completed = await OnboardingStorage().isCompleted();
    if (!mounted) {
      return;
    }

    _goTo(completed ? const AppShell() : const OnboardingPage());
  }

  void _goTo(Widget page) {
    Navigator.of(context).pushReplacement(fadeRoute(page));
  }

  @override
  void dispose() {
    _introController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _statusFor(double progress) {
    if (progress < 0.35) {
      return 'Preparando sua experiência';
    }
    if (progress < 0.75) {
      return 'Carregando suas preferências';
    }
    return 'Quase pronto';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: IllustrationCard(
                      imagePath: 'assets/images/brand/logo_celilac.png',
                      boxShaddowAlpha: 0.12,
                      width: 160.0,
                      height: 160.0,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          'CeliLac',
                          style: textTheme.displaySmall?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        const GoldAccent(width: 80.0),

                        const SizedBox(height: 12.0),
                        Text(
                          'Alimentação sem glúten e sem lactose',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.navy.withValues(alpha: 0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _footerFade,
                  child: _buildProgress(textTheme),
                ),
                const SizedBox(height: 40.0),
                FadeTransition(
                  opacity: _footerFade,
                  child: Text(
                    'versão 1.0.0',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.navy.withValues(alpha: 0.4),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final progress = _progressController.value;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusFor(progress),
                      key: ValueKey(_statusFor(progress)),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.navy.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.navy.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4.0,
                  color: AppColors.gold,
                  backgroundColor: AppColors.navy.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
