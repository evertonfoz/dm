import 'package:flutter/material.dart';
import 'package:food_safe/services/shared_preferences_services.dart';

class ConsentPageOBPage extends StatefulWidget {
  final VoidCallback onConsentGiven;
  const ConsentPageOBPage({super.key, required this.onConsentGiven});

  @override
  State<ConsentPageOBPage> createState() => _ConsentPageOBPageState();
}

class _ConsentPageOBPageState extends State<ConsentPageOBPage> {
  bool _marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SwitchListTile(
          title: const Text('Receber material de marketing'),
          value: _marketingConsent,
          onChanged: (value) {
            setState(() {
              _marketingConsent = value;
            });
          },
        ),
        ElevatedButton(
          child: const Text('Salvar Consentimento'),
          onPressed: !_marketingConsent
              ? null
              : () async {
                  await SharedPreferencesService.setMarketingConsent(
                    _marketingConsent,
                  );
                  widget.onConsentGiven();
                },
        ),
      ],
    );
  }
}
