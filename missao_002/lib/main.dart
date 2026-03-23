import 'package:flutter/material.dart';

void main() {
  runApp(const Missao2App());
}

class Missao2App extends StatelessWidget {
  const Missao2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material Design - Prática',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Material Design - Prática'),
      ),
      body: Center(
        child: Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bem-vindo(a) ao Material Design!',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text('Este é um exemplo de um card usando Material Design.'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação do botão
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
