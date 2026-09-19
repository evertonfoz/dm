import 'package:flutter/material.dart';

void main() {
  runApp(const DMApp());
}

class DMApp extends StatelessWidget {
  const DMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atividade DM',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.blue)),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividade DM'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.all(16),
              color: Colors.black12,
              height: 100.0,
              child: Container(color: Colors.black38, height: 40),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                margin: const EdgeInsets.all(16.0),
                color: Colors.yellow[100],
                shadowColor: Colors.red,
                elevation: 5.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Semana Acadêmica',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(color: Colors.black, thickness: 2.0),
                      Text('14 de Setembro de 2026'),
                      SizedBox(height: 4.0),

                      Text('Local: Auditório Central'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Botão pressionado!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              backgroundColor: Colors.green,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0)),
              ),
              action: SnackBarAction(
                label: 'Fechar',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
