import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;

class PrivacyAndTermsScreen extends StatefulWidget {
  static const routeName = '/onboarding/privacy_and_use_terms';

  const PrivacyAndTermsScreen({super.key});

  @override
  State<PrivacyAndTermsScreen> createState() => _PrivacyAndTermsScreenState();
}

class _PrivacyAndTermsScreenState extends State<PrivacyAndTermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _accepted = false;
  String _md = '';

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkdown() async {
    try {
      final data = await rootBundle.loadString(
        'assets/md/use_terms_and_privacy.md',
      );
      if (!mounted) return;
      setState(() => _md = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _md = 'Não foi possível carregar os termos.');
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onContinue() {
    if (!_accepted) return;
    Navigator.of(context).pushNamed('/onboarding/profile_select');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política & Termos')),
      body: Column(
        children: [
          Expanded(
            child: _md.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: MarkdownBody(data: _md),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Checkbox(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  // Use a clearer/high-contrast fill color for the checked state
                  fillColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                const Expanded(child: Text('Li e Concordo')),
                ElevatedButton(
                  onPressed: _accepted ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToEnd,
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }
}
