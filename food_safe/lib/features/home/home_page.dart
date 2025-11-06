import 'package:flutter/material.dart';

import '../../services/shared_preferences_services.dart';
import '../providers/infrastructure/local/providers_local_dao_shared_prefs.dart';
import '../providers/infrastructure/dtos/provider_dto.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';

  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String? _userName;
  String? _userEmail;
  List<ProviderDto> _providers = [];
  bool _loadingProviders = true;
  String? _providerError;

  AnimationController? _fabController;
  Animation<double>? _fabScale;
  bool _showOnboardingTip = false;
  // Start false to avoid showing the tutorial overlay automatically
  // before we load the persisted preference from SharedPreferences.
  bool _showProvidersTutorial = false;
  // When true, the small FAB tip will not be shown again. Mirrors the
  // persisted 'providers tutorial shown' preference.
  bool _dontShowTipAgain = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Load whether the user already confirmed the providers tutorial. If the
    // stored value is true (tutorial already shown), we don't display it again.
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
      // Persisted value indicates whether the user already confirmed the
      // tutorial (true means "don't show tip again"). We record that in
      // `_dontShowTipAgain`. Do not automatically open the overlay here; the
      // overlay should only open when the user taps the hint or uses the
      // Drawer action.
      setState(() {
        _dontShowTipAgain = shown;
        // keep _showProvidersTutorial false here; it will be opened only on
        // explicit user action.
      });
    } catch (_) {
      // ignore and keep default true
    }
  }

  Future<void> _loadUser() async {
    final name = await SharedPreferencesService.getUserName();
    final email = await SharedPreferencesService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
      _providerError = null;
    });
    try {
      final dao = ProvidersLocalDaoSharedPrefs();

      // Primeiro, tenta carregar dados existentes
      var list = await dao.listAll();

      // Do not create sample providers automatically. If none are present,
      // leave the list empty so the UI can show onboarding hints instead.

      if (!mounted) return;
      setState(() {
        _providers = list;
        _loadingProviders = false;
      });
      if (list.isEmpty) {
        // Only show the small FAB tip/animation if the user didn't opt out
        // (persisted value). We intentionally don't auto-open the full
        // tutorial overlay here.
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
    final result = await showDialog<ProviderDto>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(
          text: provider?.name ?? '',
        );
        final ratingController = TextEditingController(
          text: provider?.rating.toString() ?? '5.0',
        );
        final distanceController = TextEditingController(
          text: provider?.distance_km?.toString() ?? '',
        );
        final imageUrlController = TextEditingController(
          text: provider?.image_url ?? '',
        );
        return AlertDialog(
          title: Text(
            provider == null ? 'Novo Fornecedor' : 'Editar Fornecedor',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  autofocus: true,
                ),
                TextField(
                  controller: ratingController,
                  decoration: const InputDecoration(labelText: 'Nota (0-5)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Distância (km)',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final rating = double.tryParse(ratingController.text) ?? 5.0;
                final distance = double.tryParse(distanceController.text);
                final imageUrl = imageUrlController.text.trim().isEmpty
                    ? null
                    : imageUrlController.text.trim();
                if (name.isEmpty) return;
                final now = DateTime.now().toIso8601String();
                final dto = ProviderDto(
                  id: provider?.id ?? DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  image_url: imageUrl,
                  brand_color_hex: null,
                  rating: rating,
                  distance_km: distance,
                  metadata: null,
                  updated_at: now,
                );
                Navigator.of(context).pop(dto);
              },
              child: Text(provider == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        );
      },
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.image_url != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      provider.image_url!,
                      height: 120,
                      width: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: 280,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          width: 280,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Text('Nota: ${provider.rating.toStringAsFixed(1)}'),
              if (provider.distance_km != null)
                Text(
                  'Distância: ${provider.distance_km!.toStringAsFixed(1)} km',
                ),
              Text('Atualizado em: ${provider.updated_at}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showProviderForm(provider: provider, index: index);
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remover fornecedor?'),
                  content: Text(
                    'Tem certeza que deseja remover o fornecedor "${provider.name}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Remover'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _removeProvider(index);
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CeliLac Life'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Como começar?'),
                  content: const Text(
                    'Cadastre seu primeiro fornecedor usando o botão flutuante (+) no canto inferior direito.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName ?? 'Usuário não registrado'),
              accountEmail: Text(_userEmail ?? ''),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  _userName != null && _userName!.isNotEmpty
                      ? _userName!
                            .trim()
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                      : '?',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar perfil'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.of(
                  context,
                ).pushNamed('/profile');
                if (result == true) {
                  _loadUser();
                }
              },
              // subtitle: const Text('Atualize suas informações pessoais.'),
              // trailing: const Icon(Icons.edit),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade & consentimentos'),
              onTap: () {
                // Navigator.of(context).pop();
                _openPrivacyDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reexibir tutorial'),
              subtitle: const Text(
                'Mostrar novamente o tutorial de fornecedores',
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await SharedPreferencesService.setProvidersTutorialShown(false);
                if (!mounted) return;
                setState(() {
                  _showProvidersTutorial = true;
                  _showOnboardingTip = true;
                  _dontShowTipAgain = false;
                  _fabController?.repeat(reverse: true);
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Política de Privacidade'),
              onTap: () {
                // open local policy page or asset
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/policies');
              },
            ),
          ],
        ),
      ),
      body: _loadingProviders
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
                        // Make the small hint clickable so users can re-open the
                        // full providers tutorial overlay if they want to see it.
                        if (!mounted) return;
                        setState(() {
                          _showProvidersTutorial = true;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            // Use a fallback animation if the controller is null to
                            // avoid exceptions during the first frames or after
                            // disposal.
                            animation:
                                _fabController ?? kAlwaysCompleteAnimation,
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
                // Render the full tutorial overlay even when the providers
                // list is empty so the small clickable hint can open it.
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
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadProviders,
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 8,
                    ),
                    itemCount: _providers.length,
                    itemBuilder: (context, idx) {
                      final p = _providers[idx];
                      final isEven = idx % 2 == 0;
                      final backgroundColor = isEven
                          ? Colors.blue[50]
                          : Colors.grey[100];

                      return Dismissible(
                        key: Key(p.id.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remover fornecedor?'),
                                  content: Text(
                                    'Tem certeza que deseja remover "${p.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Remover'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (direction) async {
                          final providerToRemove = p;
                          setState(() {
                            _providers.removeAt(idx);
                          });
                          try {
                            final dao = ProvidersLocalDaoSharedPrefs();
                            await dao.clear();
                            await dao.upsertAll(_providers);
                          } catch (e) {
                            print('Erro ao salvar: $e');
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${providerToRemove.name} removido com sucesso',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Container(
                            color: backgroundColor,
                            child: GestureDetector(
                              onTap: () => _showProviderDetails(p, idx),
                              child: Row(
                                children: [
                                  if (p.image_url != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      child: SizedBox(
                                        width: 80,
                                        height: 90,
                                        child: Image.network(
                                          p.image_url!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.store,
                                                      size: 32,
                                                    ),
                                                  ),
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.store,
                                                    size: 32,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: 80,
                                      height: 90,
                                      child: Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.store),
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Nota: ${p.rating.toStringAsFixed(1)}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (p.distance_km != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Text(
                                              '${p.distance_km!.toStringAsFixed(1)} km',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Editar',
                                          onPressed: () => _showProviderForm(
                                            provider: p,
                                            index: idx,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                              // Close overlay for this session but do
                                              // NOT persist the acceptance so the
                                              // tutorial will appear again on next run.
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
                                              // Persist that the user has seen/confirmed
                                              // the providers tutorial so we don't show it
                                              // again automatically.
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show a label-style button to let the user opt-out of the tip.
            // After the user clicks it we persist the choice and hide the
            // button. Use the Drawer -> "Reexibir tutorial" action to reset.
            if (!_dontShowTipAgain)
              TextButton(
                onPressed: () async {
                  // Persist that the user doesn't want the tip anymore.
                  await SharedPreferencesService.setProvidersTutorialShown(
                    true,
                  );
                  if (!mounted) return;
                  setState(() {
                    _dontShowTipAgain = true;
                    // Ensure the overlay is closed and the small tip hidden.
                    _showProvidersTutorial = false;
                    _showOnboardingTip = false;
                  });
                  _fabController?.stop();
                  _fabController?.reset();
                },
                child: const Text('Não exibir dica novamente'),
              ),
            const SizedBox(width: 12),
            ScaleTransition(
              scale: _fabScale ?? kAlwaysCompleteAnimation,
              child: Tooltip(
                message: 'Adicionar fornecedor',
                preferBelow: false,
                child: FloatingActionButton(
                  onPressed: () => _showProviderForm(),
                  tooltip: 'Adicionar fornecedor',
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacidade & Consentimentos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Deletar nome e e-mail locais'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Deletar'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar remoção de dados'),
                        content: const Text(
                          'Deseja realmente remover seu nome e e-mail armazenados localmente?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remover'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await SharedPreferencesService.removeUserName();
                      await SharedPreferencesService.removeUserEmail();
                      if (mounted) {
                        setState(() {
                          _userName = null;
                          _userEmail = null;
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dados locais removidos.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
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
}
