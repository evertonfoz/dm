import 'package:flutter/material.dart';

class EntityListPage extends StatefulWidget {
  const EntityListPage({super.key, required this.entity});

  final String entity;

  @override
  State<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends State<EntityListPage>
    with SingleTickerProviderStateMixin {
  // Simulação de estado local (não persistente)
  bool showTip = true;
  bool showTutorial = false;
  final List<dynamic> items = []; // Layout-only: sem persistência

  late final AnimationController _tipController;

  @override
  void initState() {
    super.initState();
    _tipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (showTip) _tipController.forward();
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entity),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBody(context),
            ),
          ),

          // Overlay de tutorial central
          if (showTutorial)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tutorial',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aqui você verá uma lista com ${widget.entity.toUpperCase()}s. Use o botão flutuante para adicionar.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => showTutorial = false),
                          child: const Text('Entendi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // FAB e botão de opt-out posicionados respeitando SafeArea
      floatingActionButton: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opt-out text button
              TextButton(
                onPressed: () => setState(() => showTip = false),
                child: const Text('Não exibir dica novamente'),
              ),
              const SizedBox(width: 8),

              // FAB
              Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _tipController,
                      curve: Curves.easeOutBack,
                    ),
                    child: Visibility(
                      visible: showTip,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 70.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Toque aqui para adicionar ${widget.entity.toLowerCase()}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () => setState(() => showTutorial = true),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 72,
              // withOpacity is deprecated; use withAlpha to set opacity in 0-255 range
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum ${widget.entity.toUpperCase()} cadastrado ainda.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use o botão abaixo para criar o primeiro ${widget.entity.toLowerCase()}.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Caso a lista não esteja vazia (layout-only, sem dados reais)
    return ListView.separated(
      itemBuilder: (context, index) => ListTile(
        title: Text('${widget.entity} #${index + 1}'),
      ),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: items.length,
    );
  }
}
