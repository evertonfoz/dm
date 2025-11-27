// Placeholder notes: some onboarding-specific widgets/constants are not
// implemented in this module (FormPagesBodyPadding, FormPageHeader,
// kTitleEdgeInsets, kTitleFontWeight, CheckBoxECA, PrivacyAndUseTermsAccessButton).
import 'package:flutter/material.dart';
import '../../../../theme/color_schemes.dart';

class PrivacyAndUseTermsPage extends StatefulWidget {
  const PrivacyAndUseTermsPage({super.key});

  @override
  State<PrivacyAndUseTermsPage> createState() => _PrivacyAndUseTermsPageState();
}

class _PrivacyAndUseTermsPageState extends State<PrivacyAndUseTermsPage> {
  // Scroll controllers and flags for the full onboarding flow (kept as
  // placeholders until onboarding is implemented):
  // final ScrollController _markDownScrollController = ScrollController();
  // bool _termsWasRead = false;
  // bool _floatActionButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    // Markdown loading is deferred until the onboarding flow is implemented.
    // try {
    //   final data = await rootBundle.loadString(
    //     'assets/md/use_terms_and_privacy.md',
    //   );
    //   if (!mounted) return;
    //   setState(() => _md = data);
    // } catch (_) {
    //   if (!mounted) return;
    //   setState(() => _md = 'Não foi possível carregar os termos.');
    // }
  }

  @override
  Widget build(BuildContext context) {
    // Temporary placeholder layout while onboarding screens are under development.
    return Scaffold(
      backgroundColor: lightColorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.privacy_tip, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Tela de Termos e Privacidade em desenvolvimento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            // Placeholder for the custom access button used in the final onboarding.
            ElevatedButton(
              onPressed: () {},
              child: const Text('Continuar (placeholder)'),
            ),
          ],
        ),
      ),
      // FloatingActionButton used as a temporary action control.
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkColorScheme.primary,
        onPressed: () {},
        child: const Icon(Icons.arrow_downward, color: Colors.white),
      ),
    );
  }
}

// Modular.to.navigate('../profile_select/');
