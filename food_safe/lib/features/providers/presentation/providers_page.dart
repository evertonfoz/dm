import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../services/shared_preferences_services.dart';
import '../infrastructure/local/providers_local_dao_shared_prefs.dart';
import '../infrastructure/remote/supabase_providers_remote_datasource.dart';
import '../infrastructure/repositories/providers_repository_impl.dart';
// DTO import no longer required in UI - domain entities used instead.
import '../infrastructure/mappers/provider_mapper.dart';
import '../domain/entities/provider.dart';
import 'dialogs/provider_form_dialog.dart';
import 'dialogs/provider_details_dialog.dart';
import 'widgets/providers_fab_area.dart';
import 'widgets/provider_list_view.dart';

class ProvidersPage extends StatefulWidget {
  final void Function(VoidCallback callback)? onRegisterShowTutorial;

  const ProvidersPage({super.key, this.onRegisterShowTutorial});

  @override
  ProvidersPageState createState() => ProvidersPageState();
}

class ProvidersPageState extends State<ProvidersPage>
    with SingleTickerProviderStateMixin {
  String? _providerError;
  List<Provider> _providers = [];
  bool _loadingProviders = true;

  AnimationController? _fabController;
  Animation<double>? _fabScale;
  bool _showOnboardingTip = false;
  bool _showProvidersTutorial = false;
  bool _dontShowTipAgain = false;
  bool _syncingProviders = false;
  // NOTE: sync indicator uses transient SnackBar; no dedicated field required.

  @override
  void initState() {
    super.initState();
    // Register tutorial callback with parent if provided
    widget.onRegisterShowTutorial?.call(showTutorialAgain);

    _loadProvidersTutorialPreference().then((_) {
      if (mounted) {
        _loadProviders();
      } else {
        if (kDebugMode)
          print('[initState] Widget unmounted before _loadProviders call');
      }
    });
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fabController!, curve: Curves.elasticInOut),
    );
  }

  @override
  void dispose() {
    _fabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProvidersTutorialPreference() async {
    try {
      final shown = await SharedPreferencesService.getProvidersTutorialShown();
      if (!mounted) return;
      setState(() {
        _dontShowTipAgain = shown;
      });
    } catch (_) {
      // ignore and keep default
    }
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;

    setState(() {
      _loadingProviders = true;
      _providerError = null;
    });

    if (!mounted) return;

    try {
      final dao = ProvidersLocalDaoSharedPrefs();
      var dtoList = await dao.listAll();

      // convert to domain entities for UI
      var list = dtoList.map(ProviderMapper.toEntity).toList();

      // Apply cached data to UI immediately so users see content right away
      if (!mounted) return;

      setState(() {
        _providers = list;
        _loadingProviders = false;
      });

      // Start a background sync regardless of local cache state so cached
      // items are pushed to the remote and remote deltas are applied.
      try {
        if (!mounted) return;

        setState(() => _syncingProviders = true);

        final remote = SupabaseProvidersRemoteDatasource();
        final repo = ProvidersRepositoryImpl(remoteApi: remote, localDao: dao);

        final applied = await repo.syncFromServer();

        // reload dto cache and convert
        final reloaded = await dao.listAll();
        list = reloaded.map(ProviderMapper.toEntity).toList();

        if (kDebugMode && list.isNotEmpty) {
          print(
            '[_loadProviders] After sync - Provider: ${list.first.name}, imageUri: ${list.first.imageUri}',
          );
        }

        if (!mounted) return;

        setState(() => _syncingProviders = false);

        if (applied > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sincronização concluída ($applied itens)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('[_loadProviders] Sync error: $e');
          print(stackTrace);
        }
        if (mounted) {
          setState(() => _syncingProviders = false);
        }
        // ignore sync errors; keep showing cached data
      }

      // Update UI with synced data if sync completed and brought changes
      if (mounted && list.isNotEmpty) {
        setState(() {
          _providers = list;
        });
      }

      if (list.isEmpty) {
        if (!_dontShowTipAgain) {
          _showOnboardingTip = true;
          _fabController?.repeat(reverse: true);
        } else {
          _showOnboardingTip = false;
          _fabController?.stop();
          _fabController?.reset();
        }
      } else {
        _showOnboardingTip = false;
        _fabController?.stop();
        _fabController?.reset();
      }
    } catch (e) {
      if (kDebugMode) print('[_loadProviders] Error: $e');
      if (!mounted) return;
      setState(() {
        _providerError = 'Erro ao carregar fornecedores';
        _loadingProviders = false;
      });
    }
    // no-op: SnackBar lifecycle handled around sync block
  }

  void _showProviderForm({Provider? provider, int? index}) async {
    final result = await showProviderFormDialog(context, provider: provider);
    if (result != null) {
      final dao = ProvidersLocalDaoSharedPrefs();
      // Build new domain list and persist as DTOs
      final List<Provider> newDomain = List.from(_providers);
      if (index != null) {
        newDomain[index] = result;
      } else {
        newDomain.add(result);
      }
      final newDtos = newDomain.map(ProviderMapper.toDto).toList();
      await dao.upsertAll(newDtos);

      if (kDebugMode) {
        print(
          '[_showProviderForm] Saved locally. Provider: ${result.name}, distance: ${result.distanceKm}, updatedAt: ${result.updatedAt}',
        );
      }

      // Trigger sync to push changes to Supabase
      if (!mounted) return;
      setState(() => _syncingProviders = true);

      try {
        final remote = SupabaseProvidersRemoteDatasource();
        final repo = ProvidersRepositoryImpl(remoteApi: remote, localDao: dao);
        await repo.syncFromServer();

        if (kDebugMode) print('[_showProviderForm] Sync after edit complete');
      } catch (e) {
        if (kDebugMode) print('[_showProviderForm] Sync error: $e');
      } finally {
        if (mounted) setState(() => _syncingProviders = false);
      }

      await _loadProviders();
    }
  }

  void _showProviderDetails(Provider provider, int index) {
    showProviderDetailsDialog(
      context,
      provider,
      onEdit: () => _showProviderForm(provider: provider, index: index),
      onRemove: () => _removeProvider(index),
    );
  }

  Future<void> _removeProvider(int index) async {
    // Immediately remove from state to update UI
    final removedProvider = _providers[index];
    if (mounted) {
      setState(() {
        _providers = List.from(_providers)..removeAt(index);
      });
    }

    // Show success message immediately
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removedProvider.name} removido'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Perform persistence in background
    try {
      final dao = ProvidersLocalDaoSharedPrefs();
      final remote = SupabaseProvidersRemoteDatasource();
      final repo = ProvidersRepositoryImpl(remoteApi: remote, localDao: dao);

      // Mark as deleted for sync with server
      await repo.markProviderAsDeleted(removedProvider.id);

      // Update local cache
      final newDtos = _providers.map(ProviderMapper.toDto).toList();
      await dao.clear();
      await dao.upsertAll(newDtos);

      // Trigger sync to push deletion to Supabase
      if (mounted) setState(() => _syncingProviders = true);

      try {
        await repo.syncFromServer();
        if (kDebugMode) print('[_removeProvider] Sync after delete complete');
      } catch (e) {
        if (kDebugMode) print('[_removeProvider] Sync error: $e');
      } finally {
        if (mounted) setState(() => _syncingProviders = false);
      }
    } catch (e) {
      if (kDebugMode) print('[_removeProvider] Persistence error: $e');
      // Optionally: reload to restore state on error
      await _loadProviders();
    }
  }

  // Expose method so parent (HomePage) can trigger re-showing the tutorial.
  void showTutorialAgain() async {
    await SharedPreferencesService.setProvidersTutorialShown(false);
    if (!mounted) return;
    setState(() {
      _showProvidersTutorial = true;
      _showOnboardingTip = true;
      _dontShowTipAgain = false;
      _fabController?.repeat(reverse: true);
    });
  }

  Widget _buildTutorialItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // bottom safe area inset (eg. iPhone home indicator) to keep FAB above
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    return _loadingProviders
        ? const Center(child: CircularProgressIndicator())
        : _providerError != null
        ? Center(child: Text(_providerError!))
        : _providers.isEmpty
        ? Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nenhum fornecedor cadastrado ainda.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (_showOnboardingTip)
                Positioned(
                  right: 24,
                  bottom: 110,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _showProvidersTutorial = true;
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedBuilder(
                          animation: _fabController ?? kAlwaysCompleteAnimation,
                          builder: (context, child) {
                            final v = _fabController?.value ?? 1.0;
                            return Transform.translate(
                              offset: Offset(0, 10 * (1 - v)),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Clique aqui para começar!',
                                style: TextStyle(
                                  color: Colors.blueAccent.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_downward,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showProvidersTutorial)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Como gerenciar fornecedores',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTutorialItem(
                                    icon: Icons.edit,
                                    title: 'Editar fornecedor',
                                    description:
                                        'Toque no ícone de lápis para editar as informações do fornecedor',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTutorialItem(
                                    icon: Icons.touch_app,
                                    title: 'Ver detalhes',
                                    description:
                                        'Toque na linha do fornecedor para visualizar mais detalhes',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTutorialItem(
                                    icon: Icons.add_circle,
                                    title: 'Adicionar fornecedor',
                                    description:
                                        'Toque no botão + flutuante para adicionar um novo fornecedor',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTutorialItem(
                                    icon: Icons.refresh,
                                    title: 'Atualizar lista',
                                    description:
                                        'Puxe a tela para baixo para atualizar a lista de fornecedores',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTutorialItem(
                                    icon: Icons.swipe_left,
                                    title: 'Remover fornecedor',
                                    description:
                                        'Deslize a linha para a esquerda para remover um fornecedor',
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          if (!mounted) return;
                                          setState(() {
                                            _showProvidersTutorial = false;
                                          });
                                        },
                                        child: const Text('Fechar'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await SharedPreferencesService.setProvidersTutorialShown(
                                            true,
                                          );
                                          if (!mounted) return;
                                          setState(() {
                                            _showProvidersTutorial = false;
                                            _showOnboardingTip = false;
                                          });
                                          _fabController?.stop();
                                          _fabController?.reset();
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Li e entendi'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Floating action area (opt-out + FAB)
              Positioned(
                right: 0,
                bottom: 0,
                child: ProvidersFabArea(
                  fabScale: _fabScale,
                  dontShowTipAgain: _dontShowTipAgain,
                  bottomSafe: bottomSafe,
                  onDontShowTipAgain: () {
                    SharedPreferencesService.setProvidersTutorialShown(
                      true,
                    ).then((_) {
                      if (!mounted) return;
                      setState(() {
                        _dontShowTipAgain = true;
                        _showProvidersTutorial = false;
                        _showOnboardingTip = false;
                      });
                      _fabController?.stop();
                      _fabController?.reset();
                    });
                  },
                  onPressed: () => _showProviderForm(),
                ),
              ),
              if (_syncingProviders)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          )
        : RefreshIndicator(
            onRefresh: _loadProviders,
            child: Stack(
              children: [
                ProviderListView(
                  providers: _providers,
                  onTap: (p, idx) => _showProviderDetails(p, idx),
                  onEdit: (p, idx) =>
                      _showProviderForm(provider: p, index: idx),
                  onRemove: (idx) => _removeProvider(idx),
                ),
                if (_showProvidersTutorial)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 48,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Como gerenciar fornecedores',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTutorialItem(
                                      icon: Icons.edit,
                                      title: 'Editar fornecedor',
                                      description:
                                          'Toque no ícone de lápis para editar as informações do fornecedor',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTutorialItem(
                                      icon: Icons.touch_app,
                                      title: 'Ver detalhes',
                                      description:
                                          'Toque na linha do fornecedor para visualizar mais detalhes',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTutorialItem(
                                      icon: Icons.add_circle,
                                      title: 'Adicionar fornecedor',
                                      description:
                                          'Toque no botão + flutuante para adicionar um novo fornecedor',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTutorialItem(
                                      icon: Icons.refresh,
                                      title: 'Atualizar lista',
                                      description:
                                          'Puxe a tela para baixo para atualizar a lista de fornecedores',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTutorialItem(
                                      icon: Icons.swipe_left,
                                      title: 'Remover fornecedor',
                                      description:
                                          'Deslize a linha para a esquerda para remover um fornecedor',
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            if (!mounted) return;
                                            setState(() {
                                              _showProvidersTutorial = false;
                                            });
                                          },
                                          child: const Text('Fechar'),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await SharedPreferencesService.setProvidersTutorialShown(
                                              true,
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              _showProvidersTutorial = false;
                                              _showOnboardingTip = false;
                                            });
                                            _fabController?.stop();
                                            _fabController?.reset();
                                          },
                                          icon: const Icon(Icons.check),
                                          label: const Text('Li e entendi'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Floating action area (opt-out + FAB) for NON-empty list too
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ProvidersFabArea(
                    fabScale: _fabScale,
                    dontShowTipAgain: _dontShowTipAgain,
                    bottomSafe: bottomSafe,
                    onDontShowTipAgain: () {
                      SharedPreferencesService.setProvidersTutorialShown(
                        true,
                      ).then((_) {
                        if (!mounted) return;
                        setState(() {
                          _dontShowTipAgain = true;
                          _showProvidersTutorial = false;
                          _showOnboardingTip = false;
                        });
                        _fabController?.stop();
                        _fabController?.reset();
                      });
                    },
                    onPressed: () => _showProviderForm(),
                  ),
                ),
                if (_syncingProviders)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          );
  }
}
