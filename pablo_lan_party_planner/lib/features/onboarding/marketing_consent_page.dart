import 'package:flutter/material.dart';
import '../../core/theme.dart';

class MarketingConsentPage extends StatefulWidget {
  final VoidCallback onContinue;
  const MarketingConsentPage({super.key, required this.onContinue});

  @override
  State<MarketingConsentPage> createState() => _MarketingConsentPageState();
}

class _MarketingConsentPageState extends State<MarketingConsentPage> {
  bool _marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: slate,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read, color: cyan, size: 80),
                const SizedBox(height: 24),
                Text(
                  'Receber material de marketing',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Gostaria de receber novidades, promoções e materiais de marketing sobre eventos gamers?',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                SwitchListTile(
                  value: _marketingConsent,
                  onChanged: (val) {
                    setState(() {
                      _marketingConsent = val;
                    });
                  },
                  title: const Text(
                    'Receber material de marketing',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeThumbColor: purple,
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white10,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: widget.onContinue,
                  child: const Text('Salvar Consentimento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}