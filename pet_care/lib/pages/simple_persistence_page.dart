import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entities/pet_entity.dart';

class SimplePersistencePage extends StatefulWidget {
  const SimplePersistencePage({super.key});

  @override
  State<SimplePersistencePage> createState() => _SimplePersistencePageState();
}

class _SimplePersistencePageState extends State<SimplePersistencePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tutorController = TextEditingController();
  List<PetEntity> _pets = [];

  // String _savedName = 'Nenhum nome salvo';
  // String _savedTutor = 'Nenhum tutor salvo';

  @override
  initState() {
    super.initState();
    // // Future.microtask(() => _loadName());
    // Future.delayed(Duration(seconds: 2), () => _loadName());
    _loadName();
  }

  Future<void> _registry() async {
    setState(() {
      _pets.add(
        PetEntity(name: _nameController.text, tutorName: _tutorController.text),
      );
    });
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    // _pet = PetEntity(
    //   name: _nameController.text,
    //   tutorName: _tutorController.text,
    // );
    // var petMap = _pet?.toMap();

    // await prefs.setString('pet', jsonEncode(petMap));
  }

  Future<void> _registryAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> petsMap = _pets
        .map((pet) => pet.toMap())
        .toList();

    await prefs.setString('pets', jsonEncode(petsMap));
  }

  Future<void> _loadName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? petsString = prefs.getString('pets');
    if (petsString != null && petsString.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(petsString);
      setState(() {
        _pets = jsonList.map((json) => PetEntity.fromMap(json)).toList();
      });
    }
  }
  // setState(() {
  //   String? petString = prefs.getString('pet');
  //   if (petString != null && petString.isNotEmpty) {
  //     final json = jsonDecode(petString);

  //     _pet = PetEntity.fromMap(json);

  //     _nameController.value = TextEditingValue(
  //       text: _pet?.name ?? 'Nenhum nome salvo',
  //     );
  //     _tutorController.value = TextEditingValue(
  //       text: _pet?.tutorName ?? 'Nenhum tutor salvo',
  //     );
  //   }
  // _nameController.value = TextEditingValue(
  //   text: prefs.getString('pet') ?? 'Nenhum nome salvo',
  // );
  // });
  // }

  Future<void> _clearName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_name');

    setState(() {
      _nameController.value = TextEditingValue(text: 'Nenhum nome salvo');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Persistence')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Digite um nome'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _tutorController,
              decoration: const InputDecoration(
                labelText: 'Digite o nome do tutor',
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _registry,
                child: const Text('Registrar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _registryAll,
                child: const Text('Gravar Tudo'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return ListTile(
                  title: Text(pet.name),
                  subtitle: Text('Tutor: ${pet.tutorName}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
