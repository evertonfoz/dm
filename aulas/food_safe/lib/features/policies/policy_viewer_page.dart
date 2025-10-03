import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class PolicyViewerPage extends StatefulWidget {
  static const routeName = '/policy-viewer';
  final String policyTitle;
  final String assetPath;

  const PolicyViewerPage({
    super.key,
    required this.policyTitle,
    required this.assetPath,
  });

  @override
  State<PolicyViewerPage> createState() => _PolicyViewerPageState();
}

class _PolicyViewerPageState extends State<PolicyViewerPage> {
  final ScrollController _scrollController = ScrollController();
  String _policyContentFromMarkdown = '';
  double _scrollPosition = 0.0;
  bool _reachedEndOfDocument = false;

  @override
  void initState() {
    super.initState();
    _loadPolicyContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicyContent() async {
    final data = await DefaultAssetBundle.of(
      context,
    ).loadString(widget.assetPath);
    setState(() {
      _policyContentFromMarkdown = data;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final position = _scrollController.position;
      setState(() {
        _reachedEndOfDocument = position.maxScrollExtent <= 0;
        // _scrollPosition = position.pixels;
        // _reachedEndOfDocument = position.atEdge && position.pixels != 0;
      });
      // setState(() {
      //   _reachedEndOfDocument = false;
      //   _scrollPosition = 0.0;
      // });
      // _scrollController.jumpTo(0.0);
    });
  }

  void _onScroll() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
      _reachedEndOfDocument =
          _scrollController.position.atEdge &&
          _scrollController.position.pixels != 0;
    });
    // print(
    //   'Scroll Position: $_scrollPosition, Reached End: $_reachedEndOfDocument',
    // );
  }

  @override
  Widget build(BuildContext context) {
    // // print(_scrollController.position.atEdge);
    // // print(_scrollController.position.pixels);

    return Scaffold(
      appBar: AppBar(title: Text(widget.policyTitle)),
      body: Column(
        children: [
          LinearProgressIndicator(
            value:
                _scrollController.hasClients &&
                    _scrollController.position.maxScrollExtent > 0
                ? _scrollController.position.pixels /
                      _scrollController.position.maxScrollExtent
                : 0.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          Expanded(
            child: _policyContentFromMarkdown.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectionArea(
                        child: GptMarkdown(_policyContentFromMarkdown),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Semantics(
              button: true,
              enabled: _reachedEndOfDocument,
              label: _reachedEndOfDocument
                  ? 'Você chegou ao final do documento'
                  : 'Role até o final para habilitar',
              child: FilledButton.icon(
                onPressed: _reachedEndOfDocument
                    ? () {
                        Navigator.of(context).pop(true);
                      }
                    : null,
                icon: const Icon(Icons.check),
                label: Text('Concordo com os termos'),
              ),
            ),
          ),
          // SingleChildScrollView(
          //   controller: _scrollController,
          //   child: _policyContentFromMarkdown.isEmpty
          //       ? const Center(child: CircularProgressIndicator())
          //       : Padding(
          //           padding: const EdgeInsets.all(8.0),
          //           child: SelectionArea(
          //             child: GptMarkdown(_policyContentFromMarkdown),
          //           ),
          //         ),
          // ),
        ],
      ),
    );
  }
}
