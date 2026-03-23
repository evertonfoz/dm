import 'package:flutter/material.dart';
import 'daily_goal_entity_form_dialog.dart';

class DailyGoalListPage extends StatefulWidget {
  const DailyGoalListPage({super.key, required this.entity});

  final String entity;

  @override
  State<DailyGoalListPage> createState() => _DailyGoalListPageState();
}

class _DailyGoalListPageState extends State<DailyGoalListPage>
    with SingleTickerProviderStateMixin {
  // Simulação de estado local (não persistente)
  bool showTip = true;
  bool showTutorial = false;
  final List<dynamic> items = []; // Layout-only: sem persistência

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut),
    );
    if (showTip) _fabController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // Opt-out button positioned bottom-left
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: TextButton(
              onPressed: () => setState(() {
                showTip = false;
                // stop and reset FAB animation when tip is dismissed
                _fabController.stop();
                _fabController.reset();
              }),
              child: const Text(
                'Não exibir dica novamente',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Tip bubble positioned above FAB (bottom-right)
          if (showTip)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 72,
              child: AnimatedBuilder(
                animation: _fabController,
                builder: (context, child) {
                  final v = _fabController.value;
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - v)),
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Container(
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Standard FAB at bottom-right with subtle scale animation
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () async {
            // Abre a dialog para criar/editar uma DailyGoalEntity
            final result = await showDailyGoalEntityFormDialog(context);
            if (result != null) {
              setState(() {
                // insere no topo da lista (layout-only)
                items.insert(0, result);
                // Não ativar o tutorial automaticamente ao confirmar
                // (evita abrir outra dialog/overlay inesperada)
              });
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
