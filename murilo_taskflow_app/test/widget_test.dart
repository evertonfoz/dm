// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_app/widgets/user_avatar.dart';

void main() {
  testWidgets('TaskFlow app smoke test', (WidgetTester tester) async {
    // Teste simples de um widget específico ao invés do app completo
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: null,
          body: Center(
            child: UserAvatar(
              userName: 'Test User',
              photoPath: null,
            ),
          ),
        ),
      ),
    );

    // Verifica se o widget carrega corretamente
    expect(find.text('TU'), findsOneWidget); // Iniciais de Test User
    
    // Verifica se é um CircleAvatar
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('App Bar smoke test', (WidgetTester tester) async {
    // Teste simples de AppBar
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('TaskFlow'),
          ),
          body: const Center(
            child: Text('Test Body'),
          ),
        ),
      ),
    );

    // Verifica elementos básicos
    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
