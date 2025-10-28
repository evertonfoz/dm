// TODO: Implementar os widgets/constantes customizados abaixo para o onboarding:
// FormPagesBodyPadding, FormPageHeader, kTitleEdgeInsets, kTitleFontWeight, CheckBoxECA, PrivacyAndUseTermsAccessButton
// _listViewScrollController, _markDownScrollController, _termsWasRead, _floatActionButtonVisible, FaIcon, FontAwesomeIcons
// ATENÇÃO: Os widgets/constantes abaixo ainda não estão implementados neste projeto:
// FormPagesBodyPadding, FormPageHeader, kTitleEdgeInsets, kTitleFontWeight, CheckBoxECA, PrivacyAndUseTermsAccessButton
import 'package:flutter/material.dart';
import '../../../../theme/color_schemes.dart';

class PrivacyAndUseTermsPage extends StatefulWidget {
  const PrivacyAndUseTermsPage({super.key});

  @override
  State<PrivacyAndUseTermsPage> createState() => _PrivacyAndUseTermsPageState();
}

class _PrivacyAndUseTermsPageState extends State<PrivacyAndUseTermsPage> {
  // TODO: Substituir por _listViewScrollController se/quando implementar o onboarding completo
  // TODO: Substituir por _markDownScrollController se/quando implementar o onboarding completo
  // final ScrollController _markDownScrollController = ScrollController();
  // TODO: Substituir por _termsWasRead se/quando implementar o onboarding completo
  // bool _termsWasRead = false;
  // TODO: Substituir por _floatActionButtonVisible se/quando implementar o onboarding completo
  // bool _floatActionButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    // TODO: Reimplementar carregamento do markdown quando onboarding estiver pronto
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
    // TODO: Substituir por layout onboarding definitivo
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
            // TODO: Substituir por botão customizado (PrivacyAndUseTermsAccessButton)
            ElevatedButton(
              onPressed: () {},
              child: const Text('Continuar (placeholder)'),
            ),
          ],
        ),
      ),
      // TODO: Substituir por FloatingActionButton customizado
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkColorScheme.primary,
        onPressed: () {},
        child: const Icon(Icons.arrow_downward, color: Colors.white),
      ),
    );
  }
}

// Modular.to.navigate('../profile_select/');
