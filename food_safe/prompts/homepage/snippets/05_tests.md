// Snippet: 05_tests.md
// Instruções e trechos para os testes. Cole em um arquivo de notas para alunos.

Unit tests (prefs):
- Use SharedPreferences.setMockInitialValues({}) antes de inicializar o serviço.
- Lembre de limpar o singleton (se você adicionou resetForTests).

Exemplo (Dart):

```dart
SharedPreferences.setMockInitialValues({});
SharedPreferencesService.resetForTests();
await SharedPreferencesService.getInstance();

await SharedPreferencesService.setUserName('Alice');
expect(await SharedPreferencesService.getUserName(), 'Alice');
```

Widget tests (ProfilePage):
- Pump a página com MaterialApp (routable).
- Preencha campos, marque checkbox e acione o botão Salvar.
- Verifique os valores em SharedPreferencesService.

Dica: evite dependência de SnackBar para asserts; verifique o estado persistido nas prefs.
```