import 'package:flutter/material.dart';
import '../data/chamados_mock.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help Desk")),
      body: ListView.builder(
        itemCount: chamadosMock.length,
        itemBuilder: (context, index) {
          final chamado = chamadosMock[index];
          return Card(
            color: ((index % 2) == 0) ? Colors.grey.shade100 : Colors.white,
            child: ListTile(
              leading: Icon(Icons.report_problem),
              title: Text(chamado.titulo),
              subtitle: Text(chamado.descricao),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        const SizedBox(width: 8),
                        Text(
                          chamado.titulo,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
