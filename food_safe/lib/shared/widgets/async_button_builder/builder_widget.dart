import 'package:async_button_builder/async_button_builder.dart';
import 'package:flutter/material.dart';

import '../../../theme/color_schemes.dart';

class BuilderWidgetToAsyncButtonBuilder extends StatelessWidget {
  final ButtonState state;
  final GlobalKey? bottomPageKey;
  final Function()? callback;
  final Widget child;
  final bool isOnPressedEnabled;
  final Color? loadingColor;

  const BuilderWidgetToAsyncButtonBuilder({
    super.key,
    required this.state,
    this.bottomPageKey,
    this.callback,
    required this.child,
    required this.isOnPressedEnabled,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: state.maybeWhen(
          success: () => lightColorScheme.secondaryContainer,
          loading: () => loadingColor ?? darkColorScheme.primary,
          orElse: () => isOnPressedEnabled
              ? darkColorScheme.primary
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(
          24,
          // isOnPressedEnabled ? 12 : 0,
        ),
      ),
      width: MediaQuery.sizeOf(context).width * 0.98,
      height: 52,
      child: ElevatedButton(
        key: bottomPageKey,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          backgroundColor:
              Colors.transparent, // lightColorScheme.inversePrimary,
          foregroundColor: lightColorScheme.tertiary,
        ),
        onPressed: isOnPressedEnabled ? callback : null,
        child: child,
      ),
    );
  }
}
