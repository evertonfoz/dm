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
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await SharedPreferencesService.getUserName();
    final email = await SharedPreferencesService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  Future<void> _revokeMarketingConsent() async {
    // Show a dialog with an optional checkbox to also delete personal data
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) {
        bool deletePersonal = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Revogar consentimento e dados'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ao confirmar, o consentimento para marketing será revogado. Você pode opcionalmente apagar seu nome e e-mail locais.',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: deletePersonal,
                    onChanged: (v) =>
                        setState(() => deletePersonal = v ?? false),
                    title: const Text('Apagar nome e e-mail locais (opcional)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop({'confirm': true, 'delete': deletePersonal}),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result['confirm'] != true) return;

    final deletePersonal = result['delete'] == true;

    // Keep copies for undo
    final oldName = await SharedPreferencesService.getUserName();
    final oldEmail = await SharedPreferencesService.getUserEmail();

    // Revoke marketing consent (specific key)
    await SharedPreferencesService.revokeMarketingConsent();

    // Optionally remove personal data keys
    if (deletePersonal) {
      await SharedPreferencesService.removeUserName();
      await SharedPreferencesService.removeUserEmail();
      if (mounted) {
        setState(() {
          _userName = null;
          _userEmail = null;
        });
      }
    }

    if (!mounted) return;

    bool restored = false;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Consentimento para marketing revogado.'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () async {
                restored = true;
                // restore marketing consent
                await SharedPreferencesService.setMarketingConsent(true);
                // restore personal data if it was deleted
                if (deletePersonal) {
                  if (oldName != null)
                    await SharedPreferencesService.setUserName(oldName);
                  if (oldEmail != null)
                    await SharedPreferencesService.setUserEmail(oldEmail);
                  if (mounted) {
                    setState(() {
                      _userName = oldName;
                      _userEmail = oldEmail;
                    });
                  }
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ação desfeita.')),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 5),
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
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(_userName ?? 'Usuário não registrado'),
                accountEmail: Text(_userEmail ?? ''),
                currentAccountPicture: CircleAvatar(
                  child: Text(
                    _userName != null && _userName!.isNotEmpty
                        ? _userName!
                              .trim()
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                        : '?',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar perfil'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.of(
                    context,
                  ).pushNamed('/profile');
                  if (result == true) {
                    _loadUser();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacidade & consentimentos'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openPrivacyDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Política de Privacidade'),
                onTap: () {
                  // open local policy page or asset
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/policies');
                },
              ),
            ],
          ),
        ),
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

  void _openPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacidade & Consentimentos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gerencie suas concessões e dados pessoais.'),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Revogar consentimento para marketing'),
                trailing: ElevatedButton(
                  child: const Text('Revogar'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar revogação'),
                        content: const Text(
                          'Deseja revogar apenas o consentimento de marketing?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sim'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await SharedPreferencesService.revokeMarketingConsent();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consentimento de marketing revogado.'),
                        ),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Deletar nome e e-mail locais'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Deletar'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar remoção de dados'),
                        content: const Text(
                          'Deseja realmente remover seu nome e e-mail armazenados localmente?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remover'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await SharedPreferencesService.removeUserName();
                      await SharedPreferencesService.removeUserEmail();
                      if (mounted) {
                        setState(() {
                          _userName = null;
                          _userEmail = null;
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dados locais removidos.'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
