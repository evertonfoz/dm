import 'package:flutter/material.dart';

import '../../../../app/common/widgets/section_header.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/domain/entities/dietary_option.dart';
import '../../domain/entities/dietary_profile.dart';
import '../profile_scope.dart';
import '../widgets/discard_changes_dialog.dart';
import '../widgets/profile_privacy_note.dart';
import '../widgets/restrictions_field.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  // Um só lugar sabe como abrir o formulário: aba Perfil e Home usam este.
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ProfileFormPage());
  }

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final DietaryProfile _original;
  late DietaryProfile _draft;
  late final TextEditingController _nameController;
  bool _submitted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _original = ProfileScope.read(context).profile;
    _draft = _original;
    _nameController = TextEditingController(text: _original.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanges => _draft != _original;

  bool get _avoidsGluten =>
      _draft.restrictions.contains(DietaryOption.glutenFree);

  void _onNameChanged(String text) {
    final name = text.trim();
    setState(() {
      _draft = name.isEmpty
          ? _draft.copyWith(clearName: true)
          : _draft.copyWith(name: name);
    });
  }

  void _onRestrictionsChanged(Set<DietaryOption> restrictions) {
    setState(() {
      _draft = _draft.copyWith(
        restrictions: restrictions,
        // Sem glúten marcado, o cuidado com contaminação não se aplica.
        needsCrossContactCare:
            restrictions.contains(DietaryOption.glutenFree) &&
            _draft.needsCrossContactCare,
      );
    });
  }

  void _onCrossContactChanged(bool value) {
    setState(() {
      _draft = _draft.copyWith(needsCrossContactCare: value);
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ProfileScope.read(context);

    try {
      await controller.save(_draft);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.'),
          ),
        );
      return;
    }

    if (!mounted) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Perfil salvo')));
    Navigator.of(context).pop();
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      return;
    }
    final discard = await confirmDiscardChanges(context);
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isNotEmpty && name.length < 2) {
      return 'Use pelo menos 2 letras.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(title: const Text('Perfil alimentar')),
        // O botão fica fora da rolagem, logo acima do teclado quando ele abre.
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.sm,
                    horizontalPadding,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Como podemos te chamar?'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildNameField(),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'O que você precisa evitar?'),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RestrictionsField(
                                initialValue: _original.restrictions,
                                onChanged: _onRestrictionsChanged,
                              ),
                              const Divider(),
                              _buildCrossContactSwitch(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const ProfilePrivacyNote(),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveButton(horizontalPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nome (opcional)',
        helperText: 'Aparece só na saudação do app.',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.givenName],
      maxLength: 30,
      validator: _validateName,
      onChanged: _onNameChanged,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }

  Widget _buildCrossContactSwitch() {
    return SwitchListTile(
      value: _draft.needsCrossContactCare,
      onChanged: _avoidsGluten ? _onCrossContactChanged : null,
      contentPadding: EdgeInsets.zero,
      title: const Text('Preciso de cuidado com contaminação cruzada'),
      // Um controle desabilitado precisa dizer por quê, e essa explicação
      // não pode ficar no cinza claro de "desabilitado": ela é para ser lida.
      subtitle: _avoidsGluten
          ? const Text(
              'Mostraremos se o lugar tem área de preparo '
              'ou utensílios separados.',
            )
          : Text(
              'Disponível quando você marca Glúten.',
              style: TextStyle(color: AppColors.navy.withValues(alpha: 0.8)),
            ),
    );
  }

  Widget _buildSaveButton(double horizontalPadding) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.sm,
          horizontalPadding,
          AppSpacing.md,
        ),
        child: FilledButton(
          onPressed: _hasChanges && !_isSaving ? _save : null,
          // fromHeight: largura infinita, então o botão ocupa a linha toda,
          // como o "Próximo" do onboarding.
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Salvando',
                  ),
                )
              : const Text('Salvar perfil'),
        ),
      ),
    );
  }
}
