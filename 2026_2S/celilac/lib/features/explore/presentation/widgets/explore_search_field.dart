import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';

/// Campo de busca que só avisa a tela depois que a pessoa para de digitar.
/// Sem isso, a lista seria recalculada a cada letra.
class ExploreSearchField extends StatefulWidget {
  const ExploreSearchField({
    super.key,
    required this.query,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// O texto "oficial", vindo do controlador.
  final String query;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  @override
  State<ExploreSearchField> createState() => _ExploreSearchFieldState();
}

class _ExploreSearchFieldState extends State<ExploreSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );
  Timer? _timer;

  @override
  void didUpdateWidget(ExploreSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Limpar filtros" ou um atalho da Home mudaram a busca por fora:
    // o campo acompanha e cancela o que estava pendente.
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _timer?.cancel();
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(text));
    setState(() {}); // mostra ou esconde o botão de limpar na hora
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nome, bairro ou tipo',
        prefixIcon: const Icon(Icons.search, color: AppColors.navy),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close),
                onPressed: _clear,
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
