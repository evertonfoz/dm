import 'package:flutter/material.dart';

import '../../services/shared_preferences_services.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';

  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _revokeMarketingConsent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar Consentimento'),
        content: const Text(
          'Tem certeza que deseja revogar o consentimento para marketing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await SharedPreferencesService.revokeMarketingConsent();

    if (!mounted) return;

    bool restored = false;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text('Consentimento para marketing revogado.'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                restored = true;
                SharedPreferencesService.setMarketingConsent(true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Consentimento para marketing restaurado.'),
                    ),
                  );
                }
              },
            ),
            duration: Duration(seconds: 5),
          ),
        )
        .closed
        .then((_) {
          if (mounted && !restored) {
            Navigator.of(context).pushReplacementNamed('/onboarding');
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _revokeMarketingConsent();
        },
        tooltip: 'Revogar Consentimento',
        child: const Icon(Icons.cancel),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
