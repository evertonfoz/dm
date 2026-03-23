import 'package:flutter/material.dart';
import 'constants.dart';
import 'widgets/celilac_scaffold.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_top_image.dart';
import 'widgets/onboarding_title_text.dart';
import 'widgets/onboarding_text.dart';
import 'widgets/onboarding_bottom_button.dart';

class OnBoardingWelcomePage extends StatefulWidget {
  const OnBoardingWelcomePage({super.key});

  @override
  State<OnBoardingWelcomePage> createState() => _OnBoardingWelcomePageState();
}

class _OnBoardingWelcomePageState extends State<OnBoardingWelcomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CeliLacScaffold(
      // backgroundColor: lightColorScheme.primary, // Defina se necessário
      body: Stack(
        children: <Widget>[
          OnBoardingBackground(
            url: kBackgroundOnBoarding,
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                OnBoardingTopImage(
                  url: kOnBoardingPage01,
                ),
                OnBoardingTitleText(),
                OnBoardingText(),
                OnBoardingBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
