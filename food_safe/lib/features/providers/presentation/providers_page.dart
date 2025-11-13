import 'package:flutter/material.dart';

import '../../../services/shared_preferences_services.dart';
import '../infrastructure/local/providers_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/provider_dto.dart';
import 'dialogs/provider_form_dialog.dart';
import 'dialogs/provider_details_dialog.dart';
import 'widgets/providers_fab_area.dart';
import 'widgets/provider_list_view.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({Key? key}) : super(key: key);

  @override
  ProvidersPageState createState() => ProvidersPageState();
}

class ProvidersPageState extends State<ProvidersPage>
    with SingleTickerProviderStateMixin {
  String? _providerError;
  List<ProviderDto> _providers = [];
  bool _loadingProviders = true;

  AnimationController? _fabController;
  Animation<double>? _fabScale;
  bool _showOnboardingTip = false;
  bool _showProvidersTutorial = false;
  bool _dontShowTipAgain = false;

  @override
  void initState() {
    super.initState();
    _loadProvidersTutorialPreference().then((_) => _loadProviders());
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
    setState(() {
      _loadingProviders = true;
      _providerError = null;
    });
    try {
      final dao = ProvidersLocalDaoSharedPrefs();
      var list = await dao.listAll();
      if (!mounted) return;
      setState(() {
        _providers = list;
        _loadingProviders = false;
      });
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
      if (!mounted) return;
      setState(() {
        _providerError = 'Erro ao carregar fornecedores';
        _loadingProviders = false;
      });
    }
  }

  void _showProviderForm({ProviderDto? provider, int? index}) async {
    final result = await showProviderFormDialog(context, provider: provider);
    if (result != null) {
      final dao = ProvidersLocalDaoSharedPrefs();
      List<ProviderDto> newList = List.from(_providers);
      if (index != null) {
        newList[index] = result;
      } else {
        newList.add(result);
      }
      await dao.upsertAll(newList);
      await _loadProviders();
    }
  }

  void _showProviderDetails(ProviderDto provider, int index) {
    showProviderDetailsDialog(
      context,
      provider,
      onEdit: () => _showProviderForm(provider: provider, index: index),
      onRemove: () async => await _removeProvider(index),
    );
  }

  Future<void> _removeProvider(int index) async {
    final dao = ProvidersLocalDaoSharedPrefs();
    List<ProviderDto> newList = List.from(_providers);
    newList.removeAt(index);
    await dao.clear();
    await dao.upsertAll(newList);
    await _loadProviders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fornecedor removido com sucesso'),
          duration: Duration(seconds: 2),
        ),
      );
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
                  onRemove: (idx) async => await _removeProvider(idx),
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
              ],
            ),
          );
  }
}
