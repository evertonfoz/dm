import 'package:flutter/material.dart';
import 'app/responsive_app.dart';

void main() {
  runApp(const ResponsiveApp());
}

class ResponsiveHomePage extends StatelessWidget {
  const ResponsiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layout Responsivo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 700;

          if (useVerticalLayout) {
            return const _VerticalLayoutExample();
          }
          return const _HorizontalLayoutExample();
        },
      ),
    );
  }
}

class _VerticalLayoutExample extends StatelessWidget {
  const _VerticalLayoutExample();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoPanel(title: 'Painel A', description: 'Aparece primeiro.'),
        SizedBox(height: 16),
        InfoPanel(title: 'Painel B', description: 'Aparece abaixo.'),
      ],
    );
  }
}

class _HorizontalLayoutExample extends StatelessWidget {
  const _HorizontalLayoutExample();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InfoPanel(title: 'Painel A', description: 'À esquerda.'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: InfoPanel(title: 'Painel B', description: 'À direita.'),
          ),
        ],
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  final String title;
  final String description;

  const InfoPanel({super.key, required this.title, required this.description});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
