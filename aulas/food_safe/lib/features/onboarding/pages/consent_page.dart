import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentPageOBPage extends StatefulWidget {
  final VoidCallback onConsentGiven;
  // final PageController pageController;

  // const ConsentPageOBPage({super.key, required this.pageController});
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
                  final prefs = await SharedPreferences.getInstance();

                  await prefs.setBool('marketing_consent', _marketingConsent);

                  widget.onConsentGiven();
                },
          // () {
          // widget.pageController.nextPage(
          //   duration: const Duration(milliseconds: 300),
          //   curve: Curves.easeInOut,
          // );
          // Lógica para salvar o consentimento
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       _marketingConsent
          //           ? 'Consentimento concedido'
          //           : 'Consentimento negado',
          //     ),
          //   ),
          // );
          // },
        ),
        // Visibility(
        //   visible: _marketingConsent,
        //   maintainSize: true,
        //   maintainAnimation: true,
        //   maintainState: true,
        //   child: ElevatedButton(
        //     child: const Text('Salvar Consentimento'),
        //     onPressed: () {
        //       // Lógica para salvar o consentimento
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Text(
        //             _marketingConsent
        //                 ? 'Consentimento concedido'
        //                 : 'Consentimento negado',
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}
