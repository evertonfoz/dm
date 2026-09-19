import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PetFormPage extends StatefulWidget {
  const PetFormPage({super.key});

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _nameController;
  late TextEditingController _tutorController;
  late TextEditingController _ageController;
  String? _selectedRace;
  bool _isPriority = false;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController();
    _tutorController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _formKey.currentState?.reset();
    _nameController.dispose();
    _tutorController.dispose();
    _ageController.dispose();
  }

  void _showPetName() {
    final name = _nameController.text;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome do Pet'),
          content: Text(name),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool _isRequiredFieldsFilled(String value) {
    return value.isNotEmpty && value.trim().isNotEmpty;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _showPetName();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Pet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                items: [
                  DropdownMenuItem(value: 'Cachorro', child: Text('Cachorro')),
                  DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                ],
                onChanged: (value) {
                  _selectedRace = value.toString();
                },
                decoration: InputDecoration(
                  labelText: 'Raça',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_selectedRace == null || _selectedRace!.isEmpty) {
                    return 'Raça obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!_isRequiredFieldsFilled(value.toString())) {
                    return 'Nome obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tutorController,
                decoration: InputDecoration(
                  labelText: 'Tutor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!_isRequiredFieldsFilled(value.toString())) {
                    return 'Tutor obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Idade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!_isRequiredFieldsFilled(value.toString())) {
                    return 'Idade obrigatória';
                  }
                  int age = 0;
                  try {
                    age = int.parse(value.toString());
                  } catch (e) {
                    return 'Idade deve ser um número';
                  }
                  if (age < 0 || age > 20) {
                    return 'Idade inválida (0-20)';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Prioridade'),
                value: _isPriority,
                onChanged: (value) => setState(() {
                  _isPriority = value;
                }),
              ),
              CheckboxListTile(
                title: const Text('Termos Aceitos'),
                subtitle: const Text('Li e concordo com os termos de uso'),
                value: _termsAccepted,
                onChanged: (value) => setState(() {
                  _termsAccepted = value!;
                }),
                checkColor: Colors.white,
                activeColor: Colors.blue,
              ),

              // Row(
              //   children: [
              //     Text('Prioridade'),
              //     Switch(
              //       value: _isPriority,
              //       onChanged: (value) => setState(() {
              //         _isPriority = value;
              //       }),
              //     ),
              //   ],
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Salvar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // _formKey.currentState?.reset();
                      _nameController.clear();
                      _tutorController.clear();
                      _ageController.clear();
                    },
                    child: const Text('Limpar'),
                  ),
                ],
              ), // Temporário, apenas para teste
            ],
          ),
        ),
      ),
    );
  }
}
