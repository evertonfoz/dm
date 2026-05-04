import 'package:flutter/material.dart';

import 'model/compromisso.dart';
import 'repository_mock/compromisso_repository_mock.dart';

void main() {
  runApp(const AgendaApp());
}

class AgendaApp extends StatefulWidget {
  const AgendaApp({super.key});

  @override
  State<AgendaApp> createState() => _AgendaAppState();
}

class _AgendaAppState extends State<AgendaApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.menu, size: 48),
          title: Text('AGENDA'),
          actions: const [
            Icon(Icons.notifications, size: 48, color: Colors.grey),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: compromissos.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
                      ),
                    ),
                    title: Text(compromissos[index].titulo),
                    trailing: Column(
                      children: [
                        Text(
                          "${compromissos[index].data.day}/${compromissos[index].data.month}/${compromissos[index].data.year}",
                        ),
                        Text(
                          "${compromissos[index].data.hour}:${compromissos[index].data.minute.toString().padLeft(2, '0')}",
                        ),
                        Text(
                          compromissos[index].concluido
                              ? 'Concluído'
                              : 'Pendente',
                          style: TextStyle(
                            color: compromissos[index].concluido
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        compromissos[index].concluido =
                            !compromissos[index].concluido;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            compromissos[index].concluido
                                ? 'Compromisso "${compromissos[index].titulo}" concluído!'
                                : 'Compromisso "${compromissos[index].titulo}" marcado como pendente.',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // children: [
              //   title: Text('Academia'),
              //   // subtitle: Text('john.doe@example.com'),
              //   trailing: Column(
              //     children: [Text('Segunda-feira'), Text('08:00 - 09:00')],
              //   ),
              // ),
              // ListTile(
              //   leading: const CircleAvatar(
              //     backgroundImage: NetworkImage(
              //       'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
              //     ),
              //   ),
              //   title: Text('Reunião de Trabalho'),
              //   // subtitle: Text('jane.smith@example.com'),
              //   trailing: Column(
              //     children: [Text('Terça-feira'), Text('10:00 - 11:00')],
              //   ),
              // ),
              // ],
            ),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              compromissos.add(
                Compromisso(
                  titulo: "Novo Compromisso",
                  data: DateTime.now().add(const Duration(days: 1)),
                ),
              );
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
