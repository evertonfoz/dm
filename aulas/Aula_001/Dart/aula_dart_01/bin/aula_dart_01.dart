import 'dart:io';


void main() {
  // Declaração de variáveis
  String? nome; // Pode ser nulo
  int idade = 0; // Não pode ser nulo, inicializado com 0
  double altura = 0.0; // Não pode ser nulo, inicializado com 0.0

  // Entrada de dados
  stdout.write('Digite seu nome: ');
  nome = stdin.readLineSync();

  stdout.write('Digite sua idade: ');
  String? idadeInput = stdin.readLineSync();
  idade = int.parse(idadeInput ?? '0'); // Valor padrão caso seja nulo

  stdout.write('Digite sua altura (m): ');
  altura = double.parse(stdin.readLineSync() ?? '0');

  // Saída de dados
  print('\nDados informados:');
  print('Nome: ${nome ?? "Não informado"}');
  print('Idade: $idade anos');
  print('Altura: ${altura.toStringAsFixed(2)}m');
}
