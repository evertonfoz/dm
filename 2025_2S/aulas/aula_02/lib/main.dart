import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ContadorApp());
}

class ContadorApp extends StatelessWidget {
  const ContadorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UTFPR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const HomePage(title: 'UTFPR Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  int _contador = 0;
  List _tarefas = [
    'Aprender Flutter',
    'Praticar Dart',
    'Construir um app',
    'Estudar Banco de Dados',
    'Fazer Exercícios',
    'Revisar Algoritmos',
    'Aprender Flutter',
    'Praticar Dart',
    'Construir um app',
    'Estudar Banco de Dados',
    'Fazer Exercícios',
    'Revisar Algoritmos',
    'Aprender Flutter',
    'Praticar Dart',
    'Construir um app',
    'Estudar Banco de Dados',
    'Fazer Exercícios',
    'Revisar Algoritmos',
    'Aprender Flutter',
    'Praticar Dart',
    'Construir um app',
    'Estudar Banco de Dados',
    'Fazer Exercícios',
    'Revisar Algoritmos',
  ];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    if (kDebugMode) {
      print(_counter);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(_counter);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // _tarefas = ['Aprender Flutter', 'Praticar Dart', 'Construir um app'];
                // _contador = 0;
              });
            },
          ),
          // IconButton(icon: Icon(Icons.abc), onPressed: () {}),
          // IconButton(icon: Icon(Icons.access_alarm), onPressed: () {}),
          // IconButton(icon: Icon(Icons.baby_changing_station), onPressed: () {}),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Você pode pressionar o botão abaixo várias vezes:'),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Container(height: 50, color: Colors.yellow),
              // ),
              const SizedBox(height: 20),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Expanded(
                child: Container(
                  color: Colors.blue[100],
                  child: ListView.builder(
                    itemCount: _tarefas.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text(_tarefas[index]),
                        subtitle: Text('Detalhes da tarefa ${index + 1}'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Você selecionou: ${_tarefas[index]}',
                                style: TextStyle(color: Colors.black),
                              ),
                              duration: Duration(seconds: 3),
                              backgroundColor: Colors.amber,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
