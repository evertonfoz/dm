import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../../../theme/color_schemes.dart';
import '../constants.dart';

const String kEmailInvalidError = 'Por favor, informe um email válido';
const String kEmailNullError = 'Por favor, informe o seu e-mail';

class EmailToLoginTextField extends StatelessWidget {
  final FocusNode textFieldFocusNode;
  final TextEditingController emailController;

  const EmailToLoginTextField({
    super.key,
    required this.textFieldFocusNode,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        if (!isKeyboardVisible) {
          textFieldFocusNode.unfocus();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 50, 8, 0),
          child: Container(
            height: size.height > 1000 ? 73.5 : 63.5,
            decoration: BoxDecoration(
              color: lightColorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(25)),
              border: Border.all(color: accessFiedlsBorderColor, width: 0.15),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 5),
              child: Theme(
                data: ThemeData(hintColor: Colors.transparent),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: emailController,
                    builder: (context, value, child) {
                      return Stack(
                        children: [
                          // Placeholder - só aparece quando o campo está vazio
                          if (value.text.isEmpty)
                            SizedBox(
                              width: size.width,
                              height: 50,
                              child: Align(
                                child: Text(
                                  'Insira seu e-mail',
                                  style: TextStyle(
                                    fontSize: size.width * 0.06,
                                    color: Colors.grey.shade400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          TextFormField(
                            textAlign: TextAlign.center,
                            controller: emailController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              return null;
                            },
                            focusNode: textFieldFocusNode,
                            style: const TextStyle(
                              color: Color(0xFF1A3A52),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(top: 8),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
