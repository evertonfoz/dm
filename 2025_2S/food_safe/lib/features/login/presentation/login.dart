// TODOs — Itens pendentes do projeto original
// ✅ 1) Widgets locais: DISPONÍVEIS em widgets/
// ✅ 2) Dependências removidas: flutter_modular, responsive_builder
// ✅ 3) Widgets de app_libraries a trazer do projeto original:
//    - shared/widgets/async_button_builder/builder_widget.dart
//    - shared/widgets/async_button_builder/loading_transiction_builder.dart
//    - shared/widgets/async_button_builder/loading_widget.dart
//    - shared/widgets/async_button_builder/success_widget.dart
//    - shared/widgets/app_version.dart
// ⏳ 4) Integração com autenticação:
//    - Implementar lógica de envio de magic link com Supabase
//    - Criar serviço de autenticação (AuthService)
// ⏳ 5) Assets necessários:
//    - assets/images/login/login.png (logo da página de login)

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../../theme/color_schemes.dart';
import 'widgets/async_button_builder.dart';
import 'widgets/bottom_page_text.dart';
import 'widgets/email_to_login_textfield.dart';
import 'widgets/login_image.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bottomTextKey = GlobalKey();
  final FocusNode _textFieldFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus) {
        // TODO: Implement ensureVisibleOnTextArea when bringing from original project
        // ensureVisibleOnTextArea(textfieldKey: _bottomTextKey);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _emailController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _emailController.value.text.length,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return KeyboardVisibilityProvider(
      child: PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: lightColorScheme.tertiaryContainer,
          body: Stack(
            children: <Widget>[
              SingleChildScrollView(
                controller: _scrollController,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Column(
                    children: <Widget>[
                      const LoginImage(),
                      EmailToLoginTextField(
                        textFieldFocusNode: _textFieldFocusNode,
                        emailController: _emailController,
                      ),
                      const AsyncButtonBuilderToLoginPage(),
                      const Spacer(),
                      BottomPageText(key: _bottomTextKey),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: darkColorScheme.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
