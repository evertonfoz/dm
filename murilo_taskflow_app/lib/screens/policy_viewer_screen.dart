import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PolicyViewerScreen extends StatefulWidget {
  final String policyType; // 'privacy' or 'terms'
  final VoidCallback? onMarkAsRead;

  const PolicyViewerScreen({
    super.key,
    required this.policyType,
    this.onMarkAsRead,
  });

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  String _content = '';
  bool _isLoading = true;
  double _scrollProgress = 0.0;
  bool _hasReachedEnd = false;
  bool _canMarkAsRead = false;
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _setupScrollListener();
    // Ensure we check scroll availability after first layout/frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkScrollAvailability(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final fileName = widget.policyType == 'privacy'
          ? 'assets/docs/privacy_policy.md'
          : 'assets/docs/terms_of_service.md';

      final content = await rootBundle.loadString(fileName);
      setState(() {
        _content = content;
        _isLoading = false;
      });
      // After content is set and widget rebuilds, check the scroll availability
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkScrollAvailability(),
      );
    } catch (e) {
      setState(() {
        _content = 'Erro ao carregar o documento.';
        _isLoading = false;
      });
    }
  }

  void _checkScrollAvailability() {
    if (!_scrollController.hasClients) {
      // If not attached yet, schedule another check on next frame
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkScrollAvailability(),
      );
      return;
    }

    final pos = _scrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final current = pos.pixels;

    setState(() {
      _scrollProgress = maxScroll > 0
          ? (current / maxScroll).clamp(0.0, 1.0)
          : 0.0;
      _canScrollUp = current > 0.0;
      _canScrollDown = current < maxScroll;
      if (_scrollProgress >= 0.95 && !_hasReachedEnd) {
        _hasReachedEnd = true;
        _canMarkAsRead = true;
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Debug logging to help diagnose visibility issues of the scroll buttons
      debugPrint(
        'PolicyViewer: scroll listener -> current: $currentScroll, max: $maxScroll',
      );

      setState(() {
        _scrollProgress = maxScroll > 0
            ? (currentScroll / maxScroll).clamp(0.0, 1.0)
            : 0.0;
        _canScrollUp = currentScroll > 0.0;
        _canScrollDown = currentScroll < maxScroll;
      });

      if (_scrollProgress >= 0.95 && !_hasReachedEnd) {
        setState(() {
          _hasReachedEnd = true;
          _canMarkAsRead = true;
        });
      }
    });
  }

  void _markAsRead() {
    if (!_canMarkAsRead) return;
    try {
      widget.onMarkAsRead?.call();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('Error in _markAsRead(): $e\n$st');
    }
  }

  String get _title => widget.policyType == 'privacy'
      ? 'Política de Privacidade'
      : 'Termos de Uso';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: SizedBox(
            height: 4.0,
            child: ColoredBox(
              color: Colors.grey.shade300,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _scrollProgress,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _hasReachedEnd
                        ? Colors.green
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ColoredBox(
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            _hasReachedEnd
                                ? '\u2713 Leitura completa - Voc\u00ea pode marcar como lido'
                                : 'Progresso da leitura: ${(_scrollProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: _hasReachedEnd
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: _hasReachedEnd
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Markdown(
                        controller: _scrollController,
                        data: _content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          h3: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          p: const TextStyle(fontSize: 16, height: 1.6),
                          listBullet: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _canMarkAsRead ? _markAsRead : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: _canMarkAsRead
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                        child: Text(
                          _canMarkAsRead
                              ? 'Marcar como Lido \u2713'
                              : 'Leia até o final para continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _canMarkAsRead
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating down button (shows only when there's content below)
                if (_canScrollDown)
                  Positioned(
                    right: 16,
                    bottom: 88,
                    child: FloatingActionButton.small(
                      heroTag: 'scroll_down',
                      onPressed: _scrollPageDown,
                      child: const Icon(Icons.arrow_downward),
                      tooltip: 'Mostrar conteúdo abaixo',
                    ),
                  ),

                // Overlay top-right scroll-up button (shows below AppBar)
                if (_canScrollUp)
                  Positioned(
                    right: 16,
                    top: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'scroll_up_overlay',
                      onPressed: _scrollPageUp,
                      child: const Icon(Icons.arrow_upward),
                      tooltip: 'Mostrar conteúdo acima',
                    ),
                  ),
              ],
            ),
    );
  }

  void _scrollPageUp() async {
    if (!_scrollController.hasClients) return;
    try {
      final pos = _scrollController.position;
      final viewport = pos.viewportDimension;
      final target = (pos.pixels - viewport).clamp(0.0, pos.maxScrollExtent);
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } catch (e, st) {
      debugPrint('Error during _scrollPageUp(): $e\n$st');
    }
    if (mounted) setState(() {});
  }

  void _scrollPageDown() async {
    if (!_scrollController.hasClients) return;
    try {
      final pos = _scrollController.position;
      final viewport = pos.viewportDimension;
      final target = (pos.pixels + viewport).clamp(0.0, pos.maxScrollExtent);
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } catch (e, st) {
      debugPrint('Error during _scrollPageDown(): $e\n$st');
    }
    if (mounted) setState(() {});
  }
}
