import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialMissionApp());
}

class MaterialMissionApp extends StatefulWidget {
  const MaterialMissionApp({super.key});

  @override
  State<MaterialMissionApp> createState() => _MaterialMissionAppState();
}

class _MaterialMissionAppState extends State<MaterialMissionApp> {
  bool _isDarkMode = false;
  int _seedIndex = 0;
  int _messageIndex = 0;
  int _contentIndex = 0;

  static const List<MaterialColor> _seedOptions = <MaterialColor>[
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.deepPurple,
  ];

  static const List<String> _snackMessages = <String>[
    'Ação principal executada com sucesso!',
    'Tema e interação atualizados no app.',
    'Material 3 aplicado com feedback visual.',
    'Conteúdo dos cards renovado para análise.',
  ];

  static const List<_CardContent> _cardContents = <_CardContent>[
    _CardContent(
      title: 'Tela Inicial Inteligente',
      subtitle: 'Estrutura Material completa com foco em organização visual.',
      icon: Icons.dashboard_customize_outlined,
      details: 'Usa MaterialApp, Scaffold, AppBar, Column, Card e Text.',
    ),
    _CardContent(
      title: 'Card Informativo Dinâmico',
      subtitle: 'Exibe conteúdo atualizado e bem espaçado.',
      icon: Icons.view_agenda_outlined,
      details: 'Inclui elevation, bordas arredondadas, Padding e SizedBox.',
    ),
    _CardContent(
      title: 'Interações com Usuário',
      subtitle: 'FAB conectado ao SnackBar com ScaffoldMessenger.',
      icon: Icons.touch_app_outlined,
      details: 'A cada toque, o app varia mensagem, cor e informações.',
    ),
    _CardContent(
      title: 'Projeto Integrador',
      subtitle: 'Reúne tema, layout, cards e feedback visual.',
      icon: Icons.rocket_launch_outlined,
      details: 'Modelo pronto para portfólio e expansão em novas telas.',
    ),
  ];

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _cycleExperience(BuildContext context) {
    setState(() {
      _seedIndex = (_seedIndex + 1) % _seedOptions.length;
      _messageIndex = (_messageIndex + 1) % _snackMessages.length;
      _contentIndex = (_contentIndex + 1) % _cardContents.length;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(_snackMessages[_messageIndex]),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Color seedColor = _seedOptions[_seedIndex];

    return MaterialApp(
      title: 'Missões Material Flutter',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
      ),
      home: HomePage(
        isDarkMode: _isDarkMode,
        currentSeed: seedColor,
        currentContent: _cardContents[_contentIndex],
        currentMessage: _snackMessages[_messageIndex],
        onToggleTheme: _toggleTheme,
        onFabPressed: _cycleExperience,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.currentSeed,
    required this.currentContent,
    required this.currentMessage,
    required this.onToggleTheme,
    required this.onFabPressed,
  });

  final bool isDarkMode;
  final Color currentSeed;
  final _CardContent currentContent;
  final String currentMessage;
  final VoidCallback onToggleTheme;
  final void Function(BuildContext context) onFabPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Abrir menu',
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Material Design no Flutter'),
        centerTitle: true,
        backgroundColor: scheme.primaryContainer,
        actions: <Widget>[
          IconButton(
            tooltip: isDarkMode ? 'Ativar tema claro' : 'Ativar tema escuro',
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    Icons.flutter_dash,
                    size: 40,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Menu do Projeto',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Tela inicial'),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text('Cor-semente atual: ${_colorName(currentSeed)}'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('SnackBar configurado'),
              subtitle: const Text('Feedback visual com ScaffoldMessenger'),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              InfoCard(content: currentContent),
              const SizedBox(height: 16),
              SummaryCard(
                currentMessage: currentMessage,
                currentSeed: currentSeed,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Atualizar interface e exibir mensagem',
        onPressed: () => onFabPressed(context),
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  static String _colorName(Color color) {
    if (color == Colors.indigo) return 'indigo';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.deepPurple) return 'deepPurple';
    return 'personalizada';
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.content});

  final _CardContent content;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      elevation: 4,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(content.icon, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(content.subtitle, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            Text(content.details, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const <Widget>[
                Chip(label: Text('Material 3')),
                Chip(label: Text('Card dinâmico')),
                Chip(label: Text('Flutter UI')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.currentMessage,
    required this.currentSeed,
    required this.isDarkMode,
  });

  final String currentMessage;
  final Color currentSeed;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumo da interface',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.message_outlined, color: scheme.primary),
              title: const Text('Mensagem atual do SnackBar'),
              subtitle: Text(currentMessage),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette_outlined, color: scheme.primary),
              title: const Text('Cor-semente ativa'),
              subtitle: Text(currentSeed.toString()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.brightness_6_outlined, color: scheme.primary),
              title: const Text('Modo visual'),
              subtitle: Text(isDarkMode ? 'Escuro' : 'Claro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContent {
  const _CardContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.details,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String details;
}
