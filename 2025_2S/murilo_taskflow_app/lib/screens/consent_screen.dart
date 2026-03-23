import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import 'policy_viewer_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyPolicyRead = false;
  bool _termsRead = false;
  bool _consentGiven = false;
  bool _isLoading = false;

  bool get _canProceed => _privacyPolicyRead && _termsRead && _consentGiven;

  Future<void> _openPolicyViewer(String policyType) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PolicyViewerScreen(
          policyType: policyType,
          onMarkAsRead: () {},
        ),
      ),
    );

    if (result == true) {
      setState(() {
        if (policyType == 'privacy') {
          _privacyPolicyRead = true;
        } else {
          _termsRead = true;
        }
      });
      
      // Atualiza as preferências conforme PRD
      final prefsService = context.read<PreferencesService>();
      if (policyType == 'privacy') {
        await prefsService.setPrivacyReadV1(true);
      } else {
        await prefsService.setTermsReadV1(true);
      }
    }
  }

  Future<void> _grantConsent() async {
    if (!_canProceed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefsService = context.read<PreferencesService>();
      
      // Concede o consentimento
      await prefsService.grantConsent();
      
      // Marca onboarding como completo se for primeira vez
      if (prefsService.isFirstTimeUser) {
        await prefsService.setOnboardingCompleted(true);
        await prefsService.completeFirstTimeSetup();
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar consentimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Políticas e Consentimento'),
        automaticallyImplyLeading: false, // Remove botão de voltar
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Título e descrição
              Text(
                'Antes de continuar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Para usar o TaskFlow, precisamos do seu consentimento com nossas políticas. Por favor, leia os documentos abaixo.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Card da Política de Privacidade
              _buildPolicyCard(
                title: 'Política de Privacidade',
                description: 'Como coletamos, usamos e protegemos seus dados',
                icon: Icons.privacy_tip,
                isRead: _privacyPolicyRead,
                onTap: () => _openPolicyViewer('privacy'),
              ),
              
              const SizedBox(height: 16),
              
              // Card dos Termos de Uso
              _buildPolicyCard(
                title: 'Termos de Uso',
                description: 'Regras e condições para usar nosso serviço',
                icon: Icons.description,
                isRead: _termsRead,
                onTap: () => _openPolicyViewer('terms'),
              ),
              
              const SizedBox(height: 32),
              
              // Checkbox de consentimento
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _privacyPolicyRead && _termsRead 
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _privacyPolicyRead && _termsRead
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consentGiven,
                  onChanged: _privacyPolicyRead && _termsRead
                      ? (value) {
                          setState(() {
                            _consentGiven = value ?? false;
                          });
                        }
                      : null,
                  title: const Text(
                    'Eu li e concordo com a Política de Privacidade e os Termos de Uso',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: !(_privacyPolicyRead && _termsRead)
                      ? const Text(
                          'Leia ambos os documentos para habilitar esta opção',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Informação sobre versão
              Center(
                child: Text(
                  'Versão das políticas: ${PreferencesService.currentPolicyVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
                ),
              ),
            ),
            
            // Botão fixo na parte inferior
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed && !_isLoading ? _grantConsent : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Concordo e Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRead 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isRead ? Icons.check_circle : icon,
                  color: isRead ? Colors.green : Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Lido',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Seta
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}