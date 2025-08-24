void main() {
  // Declaração e inicialização das variáveis
  String nomeCompleto = 'Ana Clara Santos';
  int idade = 28;
  String inicialDoNome =
      nomeCompleto[0]; // String de tamanho 1 (não existe tipo 'char' em Dart)
  double altura = 1.65; // em metros

  // Exibição no console
  print('Nome completo: $nomeCompleto');
  print('Idade: $idade');
  print('Inicial do nome: $inicialDoNome');
  print('Altura: ${altura.toStringAsFixed(2)} m');
}
