import 'package:flutter/material.dart';

import '../../policies/policy_viewer_page.dart';

class GoToAccessPageOBpage extends StatelessWidget {
  const GoToAccessPageOBpage({super.key});

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
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Política de Privacidade'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return PolicyViewerPage(
                            policyTitle: 'Política de Privacidade',
                            assetPath: 'assets/policies/privacy_policy.md',
                          );
                        },
                      ),
                    );
                  },
                  child: Text('Ler'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Ir para o Acesso'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
