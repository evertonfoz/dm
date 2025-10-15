import 'package:flutter/material.dart';

import '../../services/shared_preferences_services.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';

  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _saving = false;
  bool _privacyAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await SharedPreferencesService.getUserName();
    final email = await SharedPreferencesService.getUserEmail();
    if (mounted) {
      setState(() {
        _nameController.text = name ?? '';
        _emailController.text = email ?? '';
        _privacyAccepted = false;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null) return 'Nome é obrigatório.';
    final v = value.trim();
    if (v.isEmpty) return 'Nome é obrigatório.';
    if (v.length > 100) return 'Nome muito longo.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null) return 'E-mail é obrigatório.';
    final v = value.trim();
    if (v.isEmpty) return 'E-mail é obrigatório.';
    final emailRegExp = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegExp.hasMatch(v)) return 'E-mail inválido.';
    return null;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    if (!_privacyAccepted) {
      // show dialog asking to accept privacy
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aviso de Privacidade'),
          content: const Text(
            'Ao salvar seu nome e e-mail, você concorda com a nossa Política de Privacidade. Por favor, confirme que leu e aceita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _privacyAccepted = true;
                });
                _save();
              },
              child: const Text('Aceito'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    await SharedPreferencesService.setUserName(name);
    await SharedPreferencesService.setUserEmail(email);
    await SharedPreferencesService.setPrivacyPolicyAllRead(true);

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil salvo com sucesso.')));

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Seu nome completo',
                ),
                textInputAction: TextInputAction.next,
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'seu@exemplo.com',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _privacyAccepted,
                    onChanged: (v) {
                      setState(() {
                        _privacyAccepted = v ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Li e aceito a Política de Privacidade'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
