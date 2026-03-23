import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _acceptedDataProcessing = false;
  bool _acceptedMarketing = false;

  bool get _canContinue {
    return _acceptedTerms && _acceptedPrivacy && _acceptedDataProcessing;
  }

  void _acceptAll() {
    setState(() {
      _acceptedTerms = true;
      _acceptedPrivacy = true;
      _acceptedDataProcessing = true;
      _acceptedMarketing = true;
    });
  }

  void _continue() {
    if (_canContinue) {
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Políticas e Consentimento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRose.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryRose.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 40,
                        color: AppTheme.primaryRose,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sua privacidade é importante',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leia e aceite nossos termos para continuar',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Terms and conditions
              _buildConsentCard(
                title: 'Termos de Uso',
                description:
                    'Concordo com os termos e condições de uso do aplicativo MoodJournal.',
                isRequired: true,
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value!),
              ),

              const SizedBox(height: 16),

              // Privacy policy
              _buildConsentCard(
                title: 'Política de Privacidade',
                description:
                    'Concordo com a coleta e uso dos meus dados pessoais conforme descrito na política de privacidade.',
                isRequired: true,
                value: _acceptedPrivacy,
                onChanged: (value) => setState(() => _acceptedPrivacy = value!),
              ),

              const SizedBox(height: 16),

              // Data processing
              _buildConsentCard(
                title: 'Processamento de Dados (LGPD)',
                description:
                    'Autorizo o processamento dos meus dados de humor para análise e melhorias do aplicativo.',
                isRequired: true,
                value: _acceptedDataProcessing,
                onChanged: (value) =>
                    setState(() => _acceptedDataProcessing = value!),
              ),

              const SizedBox(height: 16),

              // Marketing (optional)
              _buildConsentCard(
                title: 'Comunicações (Opcional)',
                description:
                    'Aceito receber dicas de bem-estar e atualizações do aplicativo via notificações.',
                isRequired: false,
                value: _acceptedMarketing,
                onChanged: (value) =>
                    setState(() => _acceptedMarketing = value!),
              ),

              const SizedBox(height: 24),

              // Privacy information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.indigoLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryIndigo.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryIndigo,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informações sobre seus dados',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.primaryIndigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Seus dados de humor são armazenados localmente no seu dispositivo\n'
                      '• Não compartilhamos informações pessoais com terceiros\n'
                      '• Você pode excluir seus dados a qualquer momento\n'
                      '• Utilizamos criptografia para proteger suas informações',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryIndigo,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _acceptAll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryIndigo,
                        side: const BorderSide(color: AppTheme.primaryIndigo),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aceitar Tudo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canContinue ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard({
    required String title,
    required String description,
    required bool isRequired,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primaryRose.withOpacity(0.3)
              : AppTheme.textSecondary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryRose,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: AppTheme.primaryRose,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
