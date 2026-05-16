import 'package:flutter/material.dart';

import 'pages/crud/pet_form_page.dart';

void main() {
  runApp(const PetCareAgendaApp());
}

class PetCareAgendaApp extends StatelessWidget {
  const PetCareAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetCare Agenda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: PetFormPage(), // const PetListPage(),
    );
  }
}
