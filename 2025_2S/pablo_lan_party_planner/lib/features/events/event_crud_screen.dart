import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../core/theme.dart';
import '../../models/event.dart';

class EventCrudScreen extends StatefulWidget {
  const EventCrudScreen({super.key});

  @override
  State<EventCrudScreen> createState() => _EventCrudScreenState();
}

class _EventCrudScreenState extends State<EventCrudScreen> {
  List<Event> _events = [];
  final _formKey = GlobalKey<FormState>();
  String _nome = '';
  DateTime _inicio = DateTime.now();
  DateTime _fim = DateTime.now().add(const Duration(hours: 1));
  int _duracao = 60;
  List<String> _checklist = [];
  int _quantidadePessoas = 1;
  final _checklistController = TextEditingController();

  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('events') ?? [];
    setState(() {
      _events = list.map((e) => Event.fromJson(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('events', list);
  }

  void _addOrUpdateEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final event = Event(
        nome: _nome,
        horarioInicio: _inicio,
        horarioFim: _fim,
        duracao: Duration(minutes: _duracao),
        checklist: List<String>.from(_checklist),
        quantidadePessoas: _quantidadePessoas,
      );
      setState(() {
        if (_editingIndex != null) {
          _events[_editingIndex!] = event;
        } else {
          _events.add(event);
        }
        _editingIndex = null;
        _checklist = [];
        _checklistController.clear();
      });
      await _saveEvents();
      Navigator.of(context).pop(); // Fecha o CRUD após salvar
    }
  }

  void _editEvent(int index) {
    final event = _events[index];
    setState(() {
      _editingIndex = index;
      _nome = event.nome;
      _inicio = event.horarioInicio;
      _fim = event.horarioFim;
      _duracao = event.duracao.inMinutes;
      _checklist = List<String>.from(event.checklist);
      _quantidadePessoas = event.quantidadePessoas;
    });
  }

  void _deleteEvent(int index) async {
    setState(() {
      _events.removeAt(index);
    });
    await _saveEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slate,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Eventos Gamer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Card(
                color: Colors.white10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _nome,
                        decoration: InputDecoration(
                          labelText: 'Nome do evento',
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cyan),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: purple),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSaved: (val) => _nome = val ?? '',
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Quantidade de pessoas',
                                labelStyle: const TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: cyan),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: purple),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              initialValue: _quantidadePessoas.toString(),
                              onSaved: (val) => _quantidadePessoas =
                                  int.tryParse(val ?? '1') ?? 1,
                              validator: (val) {
                                final v = int.tryParse(val ?? '');
                                if (v == null || v < 1) {
                                  return 'Informe um número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Duração (min)',
                                labelStyle: const TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: cyan),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: purple),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              initialValue: _duracao.toString(),
                              onSaved: (val) =>
                                  _duracao = int.tryParse(val ?? '60') ?? 60,
                              validator: (val) {
                                final v = int.tryParse(val ?? '');
                                if (v == null || v < 1) {
                                  return 'Informe a duração';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Início (dd/MM/yyyy HH:mm)',
                                labelStyle: const TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: cyan),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: purple),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              initialValue:
                                  DateFormat('dd/MM/yyyy HH:mm').format(_inicio),
                              onSaved: (val) {
                                try {
                                  _inicio = DateFormat('dd/MM/yyyy HH:mm')
                                      .parse(val ?? '');
                                } catch (_) {}
                              },
                              validator: (val) {
                                try {
                                  DateFormat('dd/MM/yyyy HH:mm').parse(val ?? '');
                                  return null;
                                } catch (_) {
                                  return 'Data inválida';
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Fim (dd/MM/yyyy HH:mm)',
                                labelStyle: const TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: cyan),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: purple),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              initialValue:
                                  DateFormat('dd/MM/yyyy HH:mm').format(_fim),
                              onSaved: (val) {
                                try {
                                  _fim = DateFormat('dd/MM/yyyy HH:mm')
                                      .parse(val ?? '');
                                } catch (_) {}
                              },
                              validator: (val) {
                                try {
                                  DateFormat('dd/MM/yyyy HH:mm').parse(val ?? '');
                                  return null;
                                } catch (_) {
                                  return 'Data inválida';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _checklistController,
                              decoration: InputDecoration(
                                labelText: 'Item do checklist',
                                labelStyle: const TextStyle(color: Colors.white),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: cyan),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: purple),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: cyan),
                            onPressed: () {
                              final item = _checklistController.text.trim();
                              if (item.isNotEmpty) {
                                setState(() {
                                  _checklist.add(item);
                                  _checklistController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: _checklist
                            .map((item) => Chip(
                                  label: Text(item),
                                  backgroundColor: purple.withOpacity(0.7),
                                  labelStyle: const TextStyle(color: Colors.white),
                                  deleteIcon: const Icon(Icons.close, color: Colors.white),
                                  onDeleted: () {
                                    setState(() {
                                      _checklist.remove(item);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(180, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _addOrUpdateEvent,
                          child: Text(_editingIndex == null ? 'Adicionar Evento' : 'Salvar Alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return Card(
                  color: Colors.white10,
                  child: ListTile(
                    title: Text(
                      event.nome,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Início: ${DateFormat('dd/MM/yyyy HH:mm').format(event.horarioInicio)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Fim: ${DateFormat('dd/MM/yyyy HH:mm').format(event.horarioFim)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Duração: ${event.duracao.inMinutes} min',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Pessoas: ${event.quantidadePessoas}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Checklist: ${event.checklist.join(", ")}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: cyan),
                          onPressed: () => _editEvent(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteEvent(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}