import 'package:flutter/material.dart';

class LoadingTransictionBuilderToAsyncButtonBuilder extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const LoadingTransictionBuilderToAsyncButtonBuilder({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        // ignore: use_named_constants
        end: const Offset(0, 0),
      ).animate(animation),
      child: child,
    );
  }
}
