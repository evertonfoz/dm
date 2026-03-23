import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class LeituraMdPage extends StatefulWidget {
  final String titulo;
  final String assetPath;
  final VoidCallback onLeuTudo;

  const LeituraMdPage({
    super.key,
    required this.titulo,
    required this.assetPath,
    required this.onLeuTudo,
  });

  @override
  State<LeituraMdPage> createState() => _LeituraMdPageState();
}

class _LeituraMdPageState extends State<LeituraMdPage> {
  String _conteudo = '';
  bool _leuTudo = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _carregarMd();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _carregarMd() async {
    final texto = await rootBundle.loadString(widget.assetPath);
    setState(() {
      _conteudo = texto;
    });
  }

  void _onScroll() {
    if (!_leuTudo &&
        _scrollController.hasClients &&
        (_scrollController.offset + 40 >= _scrollController.position.maxScrollExtent)) {
      setState(() {
        _leuTudo = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slate,
      appBar: AppBar(
        backgroundColor: purple,
        title: Text(widget.titulo),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _conteudo.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(
                      _conteudo,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: _leuTudo ? widget.onLeuTudo : null,
                icon: const Icon(Icons.check),
                label: const Text('Concordo com os termos'),
                style: FilledButton.styleFrom(
                  backgroundColor: _leuTudo ? purple : slate,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}