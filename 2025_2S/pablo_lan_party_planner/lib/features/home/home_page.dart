import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../consent/consent_history_screen.dart';
import '../events/event_crud_screen.dart';
import '../profile/profile_page.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/storage_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _storageService = StorageService();
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _storageService.getUserName();
    final email = await _storageService.getUserEmail();
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  void _showPrivacyDialog() {
    bool deletePersonalData = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Privacidade & Consentimentos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Revogar consentimento para marketing (sempre revogado).',
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Apagar dados pessoais (nome e e-mail)'),
                value: deletePersonalData,
                onChanged: (value) {
                  setState(() {
                    deletePersonalData = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Sempre revogar marketing
                await _storageService.setConsentMarketing(false);
                String message = 'Consentimento de marketing revogado.';
                if (deletePersonalData) {
                  await _storageService.removeUserName();
                  await _storageService.removeUserEmail();
                  message += ' Dados pessoais apagados.';
                  // Navegar para Onboarding após apagar dados
                  Navigator.of(context).pop(); // fechar diálogo
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
                // Recarregar dados se não navegou
                _loadUserData();
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _storageService.setOnboardingDone(false);
    await _storageService.removeUserName();
    await _storageService.removeUserEmail();
    await _storageService.setConsentMarketing(false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slate,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Gamer Event Platform'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName ?? 'Nome não definido'),
              accountEmail: Text(_userEmail ?? 'E-mail não definido'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
              ),
              decoration: const BoxDecoration(color: Color(0xFF6A0DAD)),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Perfil'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade & Consentimentos'),
              onTap: _showPrivacyDialog,
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sair'),
              onTap: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Eventos cadastrados\nNenhum evento cadastrado.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.event),
              label: const Text('Gerenciar Eventos'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EventCrudScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.verified_user),
              label: const Text('Revogar Consentimento'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ConsentHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
