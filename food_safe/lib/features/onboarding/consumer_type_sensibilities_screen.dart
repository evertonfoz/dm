import 'package:flutter/material.dart';

class ConsumerTypeSensibilitiesScreen extends StatefulWidget {
  static const routeName = '/onboarding/consumer_type_sensibilities';

  const ConsumerTypeSensibilitiesScreen({super.key});

  @override
  State<ConsumerTypeSensibilitiesScreen> createState() =>
      _ConsumerTypeSensibilitiesScreenState();
}

class _ConsumerTypeSensibilitiesScreenState
    extends State<ConsumerTypeSensibilitiesScreen> {
  final Set<String> _selected = {};

  final List<Map<String, String>> _options = const [
    {'key': 'gluten', 'label': 'Glúten'},
    {'key': 'lactose', 'label': 'Lactose'},
    {'key': 'nuts', 'label': 'Nozes'},
    {'key': 'eggs', 'label': 'Ovos'},
    {'key': 'seafood', 'label': 'Frutos do mar'},
    {'key': 'vegetarian', 'label': 'Vegetariano'},
  ];

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Sensibilidades')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isSmall ? 8 : 20),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.08 * 255).round()),
                      ),
                    ),
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: AssetImage(
                        'assets/images/onboarding/sensitivity.png',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Você tem alguma sensibilidade ou preferência? Selecione as que se aplicam',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final opt = _options[index];
                    final key = opt['key']!;
                    final label = opt['label']!;
                    final selected = _selected.contains(key);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        onTap: () => _toggle(key),
                        leading: CircleAvatar(
                          radius: 20,
                          child: Icon(
                            selected ? Icons.check : Icons.close,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Switch.adaptive(
                          value: selected,
                          onChanged: (_) => _toggle(key),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Save selections to preferences or pass to next screen
                    Navigator.of(context).pushNamed('/onboarding/login');
                  },
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
