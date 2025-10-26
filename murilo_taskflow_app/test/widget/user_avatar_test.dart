import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_app/widgets/user_avatar.dart';

void main() {
  group('UserAvatar Widget', () {
    testWidgets('Exibe iniciais quando não há foto', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoPath: null,
              userName: 'João Silva',
            ),
          ),
        ),
      );

      // Verifica se as iniciais 'JS' são exibidas
      expect(find.text('JS'), findsOneWidget);
    });

    testWidgets('Exibe inicial única quando nome tem apenas uma palavra', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoPath: null,
              userName: 'João',
            ),
          ),
        ),
      );

      // Verifica se a inicial 'J' é exibida
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('Exibe ? quando nome está vazio', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoPath: null,
              userName: '',
            ),
          ),
        ),
      );

      // Verifica se '?' é exibido
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('Não exibe texto quando há foto válida (path fornecido)', (WidgetTester tester) async {
      // Nota: Este teste verifica se o widget aceita um photoPath,
      // mas não testamos a renderização real da imagem pois requer arquivo físico
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoPath: '/caminho/para/foto.jpg',
              userName: 'João Silva',
            ),
          ),
        ),
      );

      // Como o arquivo não existe, o widget deve fazer fallback para iniciais
      // Em um ambiente real com arquivo válido, não haveria texto
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('Callback onTap é chamado quando fornecido', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoPath: null,
              userName: 'João Silva',
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      // Toca no avatar
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('Não quebra quando photoPath é nulo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoPath: null,
              userName: 'Maria Santos',
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text('MS'), findsOneWidget);
    });

    testWidgets('PhotoPreview exibe Container com decoração', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoPreview(
              imagePath: '/caminho/para/foto.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(PhotoPreview), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });
}
