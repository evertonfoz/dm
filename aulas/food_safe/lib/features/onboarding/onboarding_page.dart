import 'package:flutter/material.dart';

import 'pages/how_it_works_ob_page.dart';
import 'pages/welcome_ob_page.dart';

class OnboardingPage extends StatefulWidget {
  static const routeName = '/onboarding';

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get isLastPage => _currentPage == 1;
  bool get isFirstPage => _currentPage == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            // physics: const BouncingScrollPhysics(),
            // scrollDirection: Axis.vertical,
            controller: _pageController,
            children: [WellcomeOBPage(), HowItWorksOBPage()],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0, right: 16.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  child: const Text('Pular'),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible: !isFirstPage,
                      child: IconButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            _currentPage--;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, size: 48),
                      ),
                    ),
                    Visibility(
                      visible: !isLastPage,
                      child: IconButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            _currentPage++;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward, size: 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // body: SafeArea(
      //   child: Align(
      //     alignment: Alignment.bottomCenter,
      //     child: ElevatedButton(
      //       onPressed: () {
      //         Navigator.of(context).pushReplacementNamed(HomePage.routeName);
      //       },
      //       child: const Text('Começar'),
      //     ),
      //   ),
      // ),
    );
  }
}
