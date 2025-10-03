import 'package:flutter/material.dart';
import 'package:food_safe/services/shared_preferences_services.dart';

import '../../policies/listtile_policy_widget.dart';
import '../../policies/policy_viewer_page.dart';

class GoToAccessPageOBpage extends StatefulWidget {
  const GoToAccessPageOBpage({super.key});

  @override
  State<GoToAccessPageOBpage> createState() => _GoToAccessPageOBpageState();
}

class _GoToAccessPageOBpageState extends State<GoToAccessPageOBpage> {
  bool _isPrivacyPolicyRead = false;
  bool _isTermsOfUseRead = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyPolicyReadStatus();
    _checkTermsOfUseReadStatus();
  }

  void _checkPrivacyPolicyReadStatus() async {
    bool isRead = await SharedPreferencesService.getPrivacyPolicyAllRead();
    setState(() {
      _isPrivacyPolicyRead = isRead;
    });
  }

  void _checkTermsOfUseReadStatus() async {
    bool isRead = await SharedPreferencesService.getTermsOfUseReadStatus();
    setState(() {
      _isTermsOfUseRead = isRead;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/onboarding/02.png'),
          ),
          const SizedBox(height: 24),
          Text(
            'Tudo pronto para Começar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Aprenda a usar o aplicativo para garantir a segurança alimentar',
              style: Theme.of(context).textTheme.bodyMedium,
              softWrap: true,
              textAlign: TextAlign.center,
              // overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              // ListTile(
              //   leading: Icon(
              //     _isPrivacyPolicyRead ? Icons.check_circle : Icons.cancel,
              //     color: _isPrivacyPolicyRead ? Colors.green : Colors.red,
              //   ),
              //   title: const Text('Política de Privacidade'),
              //   trailing: TextButton(
              //     onPressed: _isPrivacyPolicyRead
              //         ? null
              //         : () {
              //             Navigator.of(context)
              //                 .push(
              //                   MaterialPageRoute(
              //                     builder: (context) {
              //                       return PolicyViewerPage(
              //                         policyTitle: 'Política de Privacidade',
              //                         assetPath:
              //                             'assets/policies/privacy_policy.md',
              //                       );
              //                     },
              //                   ),
              //                 )
              //                 .then((value) {
              //                   bool didRead = value ?? false;

              //                   SharedPreferencesService.setPrivacyPolicyAllRead(
              //                     didRead,
              //                   );
              //                   if (didRead) {
              //                     ScaffoldMessenger.of(context)
              //                         .showSnackBar(
              //                           const SnackBar(
              //                             content: Text(
              //                               'Obrigado por aceitar a política!',
              //                             ),
              //                           ),
              //                         )
              //                         .closed
              //                         .then((_) {
              //                           setState(() {
              //                             _isPrivacyPolicyRead = didRead;
              //                           });
              //                         });
              //                   }
              //                 });
              //           },
              //     child: Text(_isPrivacyPolicyRead ? 'Lido' : 'Ler'),
              //   ),
              // ),
              ListtilePolicyWidget(
                isPrivacyPolicyRead: _isPrivacyPolicyRead,
                assetPath: 'assets/policies/privacy_policy.md',
                policyTitle: 'Política de Privacidade',
                onPolicyRead: () {
                  setState(() {
                    _isPrivacyPolicyRead = true;
                  });
                },
              ),
              ListtilePolicyWidget(
                isPrivacyPolicyRead: _isTermsOfUseRead,
                assetPath: 'assets/policies/terms_of_use.md',
                policyTitle: 'Termos de Uso',
                onPolicyRead: () {
                  setState(() {
                    _isTermsOfUseRead = true;
                  });
                },
              ),
              ElevatedButton(
                onPressed: (_isPrivacyPolicyRead && _isTermsOfUseRead)
                    ? () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    : null,
                child: const Text('Ir para o Acesso'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
