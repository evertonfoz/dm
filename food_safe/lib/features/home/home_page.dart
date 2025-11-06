import 'package:flutter/material.dart';

import '../../services/shared_preferences_services.dart';
import '../providers/presentation/providers_page.dart';

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
  // Key to access the providers page widget (to trigger tutorial)
  final GlobalKey<ProvidersPageState> _providersKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CeliLac Life'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Como começar?'),
                  content: const Text(
                    'Cadastre seu primeiro fornecedor usando o botão flutuante (+) no canto inferior direito.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
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
              // subtitle: const Text('Atualize suas informações pessoais.'),
              // trailing: const Icon(Icons.edit),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade & consentimentos'),
              onTap: () {
                // Navigator.of(context).pop();
                _openPrivacyDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reexibir tutorial'),
              subtitle: const Text(
                'Mostrar novamente o tutorial de fornecedores',
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await SharedPreferencesService.setProvidersTutorialShown(false);
                // Ask the ProvidersPresentation widget to re-show the tutorial
                _providersKey.currentState?.showTutorialAgain();
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
      body: ProvidersPage(key: _providersKey),
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
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dados locais removidos.'),
                          ),
                        );
                      }
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
