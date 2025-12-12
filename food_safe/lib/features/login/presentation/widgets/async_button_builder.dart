// TODO: Trazer do projeto original:
// - shared/widgets/async_button_builder/builder_widget.dart
// - shared/widgets/async_button_builder/loading_transiction_builder.dart
// - shared/widgets/async_button_builder/loading_widget.dart
// - shared/widgets/async_button_builder/success_widget.dart
// Por enquanto, usando placeholders temporários

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../../../theme/color_schemes.dart';

// Temporary placeholder widgets until app_libraries is brought over
class BuilderWidgetToAsyncButtonBuilder extends StatelessWidget {
  final ButtonState state;
  final Future<void> Function()? callback;
  final bool isOnPressedEnabled;
  final Color loadingColor;
  final Widget child;

  const BuilderWidgetToAsyncButtonBuilder({
    super.key,
    required this.state,
    required this.callback,
    required this.isOnPressedEnabled,
    required this.loadingColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isOnPressedEnabled && callback != null ? () => callback!() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: loadingColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: child,
      ),
    );
  }
}

class LoadingWidgetToAsyncButtonBuilder extends StatelessWidget {
  final AnimatedTextKit animatedTexts;

  const LoadingWidgetToAsyncButtonBuilder({
    super.key,
    required this.animatedTexts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        animatedTexts,
      ],
    );
  }
}

class SuccessWidgetToAsyncButtonBuilder extends StatelessWidget {
  const SuccessWidgetToAsyncButtonBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.check, size: 28, color: Colors.white);
  }
}

class LoadingTransictionBuilderToAsyncButtonBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const LoadingTransictionBuilderToAsyncButtonBuilder({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class AsyncButtonBuilderToLoginPage extends StatefulWidget {
  const AsyncButtonBuilderToLoginPage({super.key});

  @override
  State<AsyncButtonBuilderToLoginPage> createState() =>
      _AsyncButtonBuilderToLoginPageState();
}

class _AsyncButtonBuilderToLoginPageState
    extends State<AsyncButtonBuilderToLoginPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 25, left: 20, right: 20),
      child: KeyboardDismissOnTap(
        dismissOnCapturedTaps: true,
        child: AsyncButtonBuilder(
          successWidget: const SuccessWidgetToAsyncButtonBuilder(),
          loadingWidget: LoadingWidgetToAsyncButtonBuilder(
            animatedTexts: AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText('Realizando...'),
                TyperAnimatedText('seu acesso...'),
                TyperAnimatedText('aguarde ...'),
              ],
            ),
          ),
          onPressed: () async {
            // TODO: Implement Supabase magic link authentication
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          loadingSwitchInCurve: Curves.bounceInOut,
          loadingTransitionBuilder: (child, animation) =>
              LoadingTransictionBuilderToAsyncButtonBuilder(
                animation: animation,
                child: child,
              ),
          child: Text(
            'Entrar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: lightColorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          builder: (_, child, callback, state) {
            return BuilderWidgetToAsyncButtonBuilder(
              state: state,
              callback: callback,
              isOnPressedEnabled: true,
              loadingColor: lightColorScheme.secondaryContainer,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
