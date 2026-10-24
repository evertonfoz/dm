import 'package:flutter/widgets.dart';

import 'profile_controller.dart';

class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    super.key,
    required ProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Lê e se inscreve: quem chama é reconstruído quando o perfil muda.
  /// Use no `build`.
  static ProfileController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'Nenhum ProfileScope acima deste widget.');
    return scope!.notifier!;
  }

  /// Só lê, sem se inscrever. Use em callbacks e no `initState`.
  static ProfileController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'Nenhum ProfileScope acima deste widget.');
    return scope!.notifier!;
  }
}
