// Gerado: Dialog de inserção/edição para DailyGoalEntity
// Ajuste o import/tipo se necessário. Este arquivo pressupõe que
// `DailyGoalEntity` e `GoalType` estão definidos em:
// `package:mood_journal/domain/entities/daily_goal_entity.dart`

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_journal/domain/entities/daily_goal_entity.dart';

/// Abre uma dialog para criar/editar uma DailyGoalEntity.
///
/// Retorna a instância preenchida ou `null` se cancelado.
Future<DailyGoalEntity?> showDailyGoalEntityFormDialog(
  BuildContext context, {
  DailyGoalEntity? initial,
}) {
  return showDialog<DailyGoalEntity>(
    context: context,
    builder: (ctx) => _DailyGoalEntityFormDialog(initial: initial),
  );
}

class _DailyGoalEntityFormDialog extends StatefulWidget {
  final DailyGoalEntity? initial;
  const _DailyGoalEntityFormDialog({this.initial, Key? key}) : super(key: key);

  @override
  State<_DailyGoalEntityFormDialog> createState() =>
      _DailyGoalEntityFormDialogState();
}

class _DailyGoalEntityFormDialogState
    extends State<_DailyGoalEntityFormDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _userIdController;
  GoalType? _selectedType;
  late final TextEditingController _targetValueController;
  late final TextEditingController _currentValueController;
  DateTime? _selectedDate;
  bool _isCompleted = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _idController = TextEditingController(text: initial?.id ?? '');
    _userIdController = TextEditingController(text: initial?.userId ?? '');
    _selectedType = initial?.type ?? GoalType.moodEntries;
    _targetValueController =
        TextEditingController(text: initial?.targetValue.toString() ?? '');
    _currentValueController =
        TextEditingController(text: initial?.currentValue.toString() ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _isCompleted = initial?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _userIdController.dispose();
    _targetValueController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat.yMMMd().format(date);
    } catch (_) {
      return date.toIso8601String();
    }
  }

  void _onConfirm() {
    // Validação mínima conforme especificado:
    if (_idController.text.trim().isEmpty) {
      _showError('ID é obrigatório.');
      return;
    }
    if (_userIdController.text.trim().isEmpty) {
      _showError('User ID é obrigatório.');
      return;
    }
    if (_selectedType == null) {
      _showError('Tipo de meta é obrigatório.');
      return;
    }
    final targetText = _targetValueController.text.trim();
    final currentText = _currentValueController.text.trim();
    if (targetText.isEmpty) {
      _showError('Valor alvo (targetValue) é obrigatório.');
      return;
    }
    if (currentText.isEmpty) {
      _showError('Valor atual (currentValue) é obrigatório.');
      return;
    }

    final targetValue = int.tryParse(targetText);
    final currentValue = int.tryParse(currentText);
    if (targetValue == null || targetValue <= 0) {
      _showError('Valor alvo deve ser um número inteiro maior que 0.');
      return;
    }
    if (currentValue == null || currentValue < 0) {
      _showError('Valor atual deve ser um inteiro >= 0.');
      return;
    }

    final date = _selectedDate ?? DateTime.now();

    final dto = DailyGoalEntity(
      id: _idController.text.trim(),
      userId: _userIdController.text.trim(),
      type: _selectedType!,
      targetValue: targetValue,
      currentValue: currentValue,
      date: date,
      isCompleted: _isCompleted,
    );

    Navigator.of(context).pop(dto);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Meta Diária' : 'Adicionar Meta Diária'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ID
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              // User ID
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'User ID'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              // Tipo (enum)
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Tipo de meta'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GoalType>(
                    value: _selectedType,
                    isExpanded: true,
                    items: GoalType.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text('${g.icon} ${g.description}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Target Value (int)
              TextFormField(
                controller: _targetValueController,
                decoration: const InputDecoration(
                    labelText: 'Valor alvo (targetValue)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              // Current Value (int)
              TextFormField(
                controller: _currentValueController,
                decoration: const InputDecoration(
                    labelText: 'Valor atual (currentValue)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              // Date picker
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data'),
                      child: Text(
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : 'Selecionar data',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Escolher'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // isCompleted
              Row(
                children: [
                  const Expanded(child: Text('Concluída?')),
                  Switch(
                    value: _isCompleted,
                    onChanged: (v) => setState(() => _isCompleted = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}
