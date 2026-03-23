import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/task_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  void _showRevokeConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar Consentimento'),
        content: const Text(
          'Tem certeza que deseja revogar seu consentimento? '
          'Isso fará com que você precise aceitar novamente as políticas '
          'na próxima vez que usar o aplicativo.\n\n'
          'Seus dados de tarefas serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _revokeConsent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
  }

  void _revokeConsent() async {
    try {
      final prefsService = context.read<PreferencesService>();
      await prefsService.revokeConsent();

      if (mounted) {
        // Mostra SnackBar com opção de desfazer
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final snackBar = SnackBar(
          content: const Text('Consentimento revogado'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Desfazer',
            textColor: Colors.white,
            onPressed: () async {
              // Restaura o consentimento
              await prefsService.grantConsent();
              await prefsService.setOnboardingCompleted(true);
              
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Consentimento restaurado'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        );

        scaffoldMessenger.showSnackBar(snackBar);

        // Aguarda um pouco para ver se o usuário vai desfazer
        await Future.delayed(const Duration(seconds: 6));

        // Se ainda estiver mounted e o consentimento foi revogado, redireciona
        if (mounted && !prefsService.hasValidConsent) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/splash',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao revogar consentimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Consumer<PreferencesService>(
        builder: (context, prefsService, child) {
          return ListView(
            children: [
              // Seção de Privacidade
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Privacidade e Dados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Status do consentimento
              ListTile(
                leading: Icon(
                  prefsService.hasValidConsent 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: prefsService.hasValidConsent 
                      ? Colors.green 
                      : Colors.orange,
                ),
                title: const Text('Status do Consentimento'),
                subtitle: Text(
                  prefsService.hasValidConsent
                      ? 'Consentimento ativo desde ${_formatDate(prefsService.acceptedAt)}'
                      : 'Consentimento não concedido ou expirado',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showConsentDetailsDialog();
                },
              ),

              // Visualizar políticas
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Política de Privacidade'),
                subtitle: const Text('Revisar como seus dados são tratados'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/policy-viewer/privacy');
                },
              ),

              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Termos de Uso'),
                subtitle: const Text('Revisar termos e condições'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/policy-viewer/terms');
                },
              ),

              const Divider(),

              // Revogar consentimento
              ListTile(
                leading: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                title: const Text(
                  'Revogar Consentimento',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'Retirar permissão para uso de dados',
                ),
                onTap: prefsService.hasValidConsent 
                    ? _showRevokeConsentDialog 
                    : null,
              ),

              const Divider(),

              // Seção de Informações
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Informações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Sobre o TaskFlow'),
                subtitle: const Text('Versão 1.0.0'),
                onTap: () {
                  _showAboutDialog();
                },
              ),

              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Ajuda e Suporte'),
                subtitle: const Text('Como usar o aplicativo'),
                onTap: () {
                  // Implementar tela de ajuda
                },
              ),

              // Seção de Debug (apenas para desenvolvimento)
              const Divider(),
              const ListTile(
                leading: Icon(Icons.bug_report, color: Colors.orange),
                title: Text(
                  'Debug',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Ferramentas de desenvolvimento'),
              ),
              
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text('Limpar Dados'),
                subtitle: const Text('Reset completo do app (Cuidado!)'),
                onTap: () {
                  _showResetDialog();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConsentDetailsDialog() {
    final prefsService = context.read<PreferencesService>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Consentimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status:', prefsService.hasValidConsent ? 'Ativo' : 'Inativo'),
            _buildDetailRow('Versão das Políticas:', prefsService.policyVersion),
            _buildDetailRow('Data de Aceite:', _formatDate(prefsService.acceptedAt)),
            _buildDetailRow('Política de Privacidade:', prefsService.isPrivacyPolicyAccepted ? 'Aceita' : 'Não aceita'),
            _buildDetailRow('Termos de Uso:', prefsService.isTermsAccepted ? 'Aceitos' : 'Não aceitos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'N/A' : value),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'TaskFlow',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.task_alt,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'TaskFlow é um aplicativo de gerenciamento de tarefas '
          'que ajuda você a organizar sua vida com simplicidade.',
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset Completo'),
          ],
        ),
        content: const Text(
          '⚠️ ATENÇÃO: Esta ação irá:\n\n'
          '• Limpar todas as tarefas\n'
          '• Limpar todas as preferências\n'
          '• Voltar o app ao estado inicial\n\n'
          'Esta ação não pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('LIMPAR TUDO'),
          ),
        ],
      ),
    );
  }

  void _performReset() async {
    try {
      final prefsService = context.read<PreferencesService>();
      final taskService = context.read<TaskService>();
      
      // Limpa todas as tarefas
      await taskService.clearAllTasks();
      
      // Limpa todas as preferências
      await prefsService.clearAllPreferences();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reset completo realizado! Reiniciando app...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Aguarda um pouco e então navega para o splash
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/splash',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao fazer reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}