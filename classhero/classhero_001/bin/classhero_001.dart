import 'dart:io';

void main() {
  stdout.write('Digite sua idade: ');
  final entrada = stdin.readLineSync();
  final int idade = int.tryParse(entrada ?? '') ?? 0;

  final bool maioridade = idade >= 18;

  print('Idade: $idade');
  print('Maior de idade? $maioridade'); // true ou false
}
