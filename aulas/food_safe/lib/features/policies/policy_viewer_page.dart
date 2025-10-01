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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.policyTitle)),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: _policyContentFromMarkdown.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectionArea(
                  child: GptMarkdown(_policyContentFromMarkdown),
                ),
              ),
      ),
    );
  }
}
