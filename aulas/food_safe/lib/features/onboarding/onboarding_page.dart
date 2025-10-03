import 'package:flutter/material.dart';
import 'package:food_safe/features/onboarding/widgets/dots_indicator.dart';

import 'pages/consent_page.dart';
import 'pages/go_to_access_page_ob_page.dart';
import 'pages/how_it_works_ob_page.dart';
import 'pages/welcome_ob_page.dart';

class OnboardingPage extends StatefulWidget {
  static const routeName = '/onboarding';

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _totalPagesInOBPage = 4;
  final _consentPageIndex = 2;
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get isLastPage => _currentPage >= _consentPageIndex;
  bool get isFirstPage => _currentPage == 0;

  _onConsentGiven() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Column(
                children: [
                  // Container(height: 100, color: Colors.red),
                  Expanded(
                    child: PageView(
                      // physics: const BouncingScrollPhysics(),
                      // scrollDirection: Axis.vertical,
                      controller: _pageController,
                      children: [
                        WellcomeOBPage(),
                        HowItWorksOBPage(),
                        ConsentPageOBPage(onConsentGiven: _onConsentGiven),
                        GoToAccessPageOBpage(),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _currentPage < (_totalPagesInOBPage - 1),

                    child: DotsIndicator(
                      totalDots: _totalPagesInOBPage,
                      currentIndex: _currentPage,
                    ),
                  ),
                  // Container(height: 200, color: Colors.blue),
                ],
              ),
            ),
          ),

          if (!isLastPage)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, right: 16.0),
                  child: TextButton(
                    onPressed: () {
                      _pageController.jumpToPage(_consentPageIndex);
                      setState(() {
                        _currentPage = _consentPageIndex;
                      });
                      // Navigator.of(context).pushReplacementNamed('/home');
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
                      visible: !isFirstPage && !isLastPage,
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
    );
  }
}
