import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool available;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.available,
  });
}

class FakeProductsRepository {
  static final List<Product> _items = [
    const Product(
      id: '1',
      name: 'Notebook 14"',
      category: 'Eletrônicos',
      price: 3499.90,
      available: true,
    ),
    const Product(
      id: '2',
      name: 'Fone Bluetooth',
      category: 'Eletrônicos',
      price: 199.90,
      available: true,
    ),
    const Product(
      id: '3',
      name: 'Camiseta Algodão',
      category: 'Roupas',
      price: 59.90,
      available: false,
    ),
    const Product(
      id: '4',
      name: 'Calça Jeans',
      category: 'Roupas',
      price: 129.90,
      available: true,
    ),
    const Product(
      id: '5',
      name: 'Algoritmos em C',
      category: 'Livros',
      price: 89.00,
      available: true,
    ),
  ];

  /// Simula uma busca assíncrona (como se fosse numa API/BD).
  static Future<List<Product>> searchByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final q = category.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _items
        .where((p) => p.category.toLowerCase() == q)
        .toList(growable: false);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Busca por Categoria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const CategorySearchPage(),
    );
  }
}

class CategorySearchPage extends StatefulWidget {
  const CategorySearchPage({super.key});

  @override
  State<CategorySearchPage> createState() => _CategorySearchPageState();
}

class _CategorySearchPageState extends State<CategorySearchPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<Product> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome de uma categoria.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
    });

    try {
      final items = await FakeProductsRepository.searchByCategory(query);
      if (!mounted) return;
      setState(() => _results = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtPrice(double v) {
    // Formata simples no padrão brasileiro (sem usar intl para manter o exemplo “puro”).
    final s = v.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos por Categoria')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Campo + Botão
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Nome da categoria',
                        hintText: 'Ex.: Eletrônicos, Livros, Roupas',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),

              // Lista de resultados
              Expanded(
                child: _results.isEmpty && !_loading
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.8),
                        itemBuilder: (context, i) {
                          final p = _results[i];
                          final leadingLetter = p.name.isNotEmpty
                              ? p.name[0].toUpperCase()
                              : '?';
                          return ListTile(
                            leading: CircleAvatar(child: Text(leadingLetter)),
                            title: Text(p.name),
                            subtitle: Text(
                              'Categoria: ${p.category} • ${_fmtPrice(p.price)}',
                            ),
                            trailing: Icon(
                              p.available
                                  ? Icons.check_circle
                                  : Icons.cancel_outlined,
                              color: p.available ? Colors.green : Colors.red,
                              semanticLabel: p.available
                                  ? 'Disponível'
                                  : 'Indisponível',
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 48, color: color),
          const SizedBox(height: 8),
          Text(
            'Nenhum produto encontrado.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Dica: tente "Eletrônicos", "Livros" ou "Roupas".',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
