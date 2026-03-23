void main() {
  // Declaração e inicialização das variáveis
  String nomeCompleto = 'Carlos Alberto Silva';
  int idade = 30;
  double altura = 1.75; // use ponto para decimais em Dart

  // A inicial pode ser derivada do nome:
  String inicial = nomeCompleto.trim().substring(0, 1).toUpperCase();

  // Exibição no console
  print('Nome completo: $nomeCompleto');
  print('Idade: $idade anos');
  print('Inicial do nome: $inicial');
  print('Altura: ${altura.toStringAsFixed(2)} m');
}
