import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../../../theme/color_schemes.dart';

// TODO: Trazer app_version.dart do projeto original
// Por enquanto usando placeholder temporário simples
class AppVersionWidget extends StatelessWidget {
  const AppVersionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'v0.0.1',
      style: TextStyle(
        color: darkColorScheme.primary.withAlpha((0.6 * 255).round()),
        fontSize: 12,
      ),
    );
  }
}

class BottomPageText extends StatelessWidget {
  const BottomPageText({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: Column(
        children: [
          AutoSizeText(
            'Precisamos somente do seu e-mail.\nNenhuma senha será '
            'solicitada.\nVocê receberá um email com as orientações\npara '
            'concluir seu cadastro.',
            style: TextStyle(
              color: darkColorScheme.primary,
              fontSize: size.width * 0.02,
            ),
            maxLines: 4,
            textAlign: TextAlign.center,
            minFontSize: 14,
          ),
          SizedBox(height: size.height * 0.02),
          const AppVersionWidget(),
        ],
      ),
    );
  }
}
