import 'package:flutter/material.dart';

import '../../services/shared_preferences_services.dart';
import 'policy_viewer_page.dart';

class ListtilePolicyWidget extends StatelessWidget {
  final bool isPrivacyPolicyRead;
  final String assetPath;
  final String policyTitle;
  final VoidCallback onPolicyRead;

  const ListtilePolicyWidget({
    super.key,
    required this.isPrivacyPolicyRead,
    required this.assetPath,
    required this.policyTitle,
    required this.onPolicyRead,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isPrivacyPolicyRead ? Icons.check_circle : Icons.cancel,
        color: isPrivacyPolicyRead ? Colors.green : Colors.red,
      ),
      title: Text(policyTitle),
      trailing: TextButton(
        onPressed: isPrivacyPolicyRead
            ? null
            : () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) {
                          return PolicyViewerPage(
                            policyTitle: policyTitle,
                            assetPath: assetPath,
                          );
                        },
                      ),
                    )
                    .then((value) {
                      bool didRead = value ?? false;

                      SharedPreferencesService.setPrivacyPolicyAllRead(didRead);
                      if (didRead) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Obrigado por aceitar a $policyTitle',
                                ),
                              ),
                            )
                            .closed
                            .then((_) {
                              onPolicyRead();
                            });
                      }
                    });
              },
        child: Text(isPrivacyPolicyRead ? 'Lido' : 'Ler'),
      ),
    );
  }
}
