import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../onboarding/onboarding_screen.dart';

class ConsentHistoryScreen extends StatefulWidget {
  const ConsentHistoryScreen({super.key});

  @override
  State<ConsentHistoryScreen> createState() => _ConsentHistoryScreenState();
}

class _ConsentHistoryScreenState extends State<ConsentHistoryScreen> {
  String? _consentInfo;
  bool _consentAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadConsentInfo();
  }

  Future<void> _loadConsentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedInfo = prefs.getString('consent_info');
    final accepted = prefs.getBool('consent_accepted') ?? false;
    setState(() {
      _consentInfo = encryptedInfo;
      _consentAccepted = accepted;
    });
  }

  Map<String, dynamic>? _getConsentData() {
    if (_consentInfo != null) {
      return {
        'info': 'Dados protegidos por criptografia.',
        'hash': _consentInfo,
      };
    }
    return null;
  }

  Future<void> _revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', false);
    await prefs.setBool('consent_accepted', false);
    await prefs.remove('consent_info');
    setState(() {
      _consentAccepted = false;
      _consentInfo = null;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consentData = _getConsentData();

    return Scaffold(
      backgroundColor: slate,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Histórico de Consentimento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user, color: cyan, size: 60),
            const SizedBox(height: 16),
            Text(
              'Status atual:',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _consentAccepted
                  ? 'Consentimento ACEITO'
                  : 'Consentimento NÃO ACEITO',
              style: TextStyle(
                color: _consentAccepted ? cyan : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            if (consentData != null) ...[
              Text(
                consentData['info'],
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Hash: ${consentData['hash']}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ] else ...[
              const Text(
                'Nenhum consentimento registrado.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 32),
            if (_consentAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    minimumSize: const Size(180, 48),
                  ),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    'Revogar Consentimento',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: slate,
                        title: Text('Revogar Consentimento', style: TextStyle(color: purple)),
                        content: const Text(
                          'Tem certeza que deseja revogar o consentimento? Você será redirecionado para o início do app.',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar', style: TextStyle(color: cyan)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text('Revogar', style: TextStyle(color: purple)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _revokeConsent();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}