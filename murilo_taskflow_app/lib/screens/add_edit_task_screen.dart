import 'package:flutter/material.dart';
import '../models/task.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedPriority = widget.task!.priority;
      _selectedDueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Prioridade',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de Vencimento (opcional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDueDate != null
                        ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                        : 'Selecionar data',
                    style: TextStyle(
                      color: _selectedDueDate != null 
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              if (_selectedDueDate != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                    },
                    child: const Text('Remover data'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        isCompleted: widget.task?.isCompleted ?? false,
      );
      
      Navigator.of(context).pop(task);
    }
  }
}