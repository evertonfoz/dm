import 'package:flutter/material.dart';
import 'dart:async';

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
  Timer? _tipTimer;
  bool _showProvidersTutorial = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProviders();
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
    _tipTimer?.cancel();
    super.dispose();
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

      // Se não houver dados, cria dados de teste
      if (list.isEmpty) {
        final imageUrls = [
          'https://img.freepik.com/fotos-gratis/vista-superior-de-uma-mesa-comida-saudavel_23-2148574952.jpg',
          'https://media.istockphoto.com/id/1130860236/pt/foto/healthy-food-background.jpg?s=612x612&w=0&k=20&c=6QnQw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw1Qw',
          'https://img.freepik.com/fotos-gratis/composicao-de-alimentos-saudaveis_23-2148574950.jpg',
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=facearea&w=128&q=80',
          'https://www.foodiesfeed.com/wp-content/uploads/2023/10/healthy-food-table.jpg',
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
          'https://cdn.pixabay.com/photo/2017/01/20/15/06/vegetables-1995056_1280.jpg',
          'https://burst.shopifycdn.com/photos/healthy-breakfast.jpg?width=925&format=pjpg&exif=1&iptc=1',
          'https://www.stockvault.net/data/2019/05/07/265181/preview16.jpg',
          'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=facearea&w=128&q=80',
        ];
        list = List.generate(
          20,
          (i) => ProviderDto(
            id: 1000 + i,
            name: 'Fornecedor ${i + 1}',
            image_url: imageUrls[i % imageUrls.length],
            brand_color_hex: null,
            rating: 3.5 + (i % 5) * 0.3,
            distance_km: (i % 7 == 0) ? null : 1.2 + i * 0.7,
            metadata: null,
            updated_at: DateTime.now()
                .subtract(Duration(days: i))
                .toIso8601String(),
          ),
        );
        await dao.upsertAll(list);
      }

      if (!mounted) return;
      setState(() {
        _providers = list;
        _loadingProviders = false;
      });
      if (list.isEmpty) {
        _showOnboardingTip = true;
        _fabController?.repeat(reverse: true);
        _tipTimer?.cancel();
        _tipTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _showOnboardingTip = false);
          _fabController?.stop();
          _fabController?.reset();
        });
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedBuilder(
                          animation: _fabController!,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, 10 * (1 - _fabController!.value)),
                            child: child,
                          ),
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
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _showProvidersTutorial = false;
                                          });
                                        },
                                        icon: const Icon(Icons.close),
                                        label: const Text('Fechar'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                        ),
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
      floatingActionButton: ScaleTransition(
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
