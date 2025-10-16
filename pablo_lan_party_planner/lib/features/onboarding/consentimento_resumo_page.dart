import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ConsentimentoResumoPage extends StatelessWidget {
  final VoidCallback onLerPolitica;
  final VoidCallback onLerTermos;
  final VoidCallback onAvancar;
  final bool politicaLida;
  final bool termosLidos;

  const ConsentimentoResumoPage({
    super.key,
    required this.onLerPolitica,
    required this.onLerTermos,
    required this.onAvancar,
    required this.politicaLida,
    required this.termosLidos,
  });

  @override
  Widget build(BuildContext context) {
    final podeAvancar = politicaLida && termosLidos;
    return SafeArea(
      child: Scaffold(
        backgroundColor: slate,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: cyan, size: 80),
                const SizedBox(height: 24),
                Text(
                  'Tudo pronto para Começar',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Leia e aceite os termos para garantir sua segurança e privacidade.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ListTile(
                  leading: Icon(
                    politicaLida ? Icons.check_circle : Icons.cancel,
                    color: politicaLida ? cyan : Colors.redAccent,
                  ),
                  title: const Text('Política de Privacidade', style: TextStyle(color: Colors.white)),
                  trailing: TextButton(
                    onPressed: onLerPolitica,
                    child: const Text('Ler', style: TextStyle(color: cyan)),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    termosLidos ? Icons.check_circle : Icons.cancel,
                    color: termosLidos ? cyan : Colors.redAccent,
                  ),
                  title: const Text('Termos de Uso', style: TextStyle(color: Colors.white)),
                  trailing: TextButton(
                    onPressed: onLerTermos,
                    child: const Text('Ler', style: TextStyle(color: cyan)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: podeAvancar ? purple : Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(220, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: podeAvancar ? onAvancar : null,
                  child: const Text('Avançar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}