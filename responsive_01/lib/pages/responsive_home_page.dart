import 'package:flutter/material.dart';
import '../layouts/vertical_layout_example.dart';
import '../layouts/horizontal_layout_example.dart';

class ResponsiveHomePage extends StatelessWidget {
  const ResponsiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layout Responsivo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 700;

          if (useVerticalLayout) {
            return const VerticalLayoutExample();
          }
          return const HorizontalLayoutExample();
        },
      ),
    );
  }
}
