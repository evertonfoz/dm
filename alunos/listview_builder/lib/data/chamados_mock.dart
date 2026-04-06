import '../models/chamado.dart';

List<Chamado> chamadosMock = [
  Chamado(
    titulo: "Erro no sistema",
    descricao: "Sistema não abre",
    status: "aberto",
    prioridade: 3,
    data: DateTime.now(),
  ),
  Chamado(
    titulo: "Impressora não funciona",
    descricao: "A impressora não imprime",
    status: "em andamento",
    prioridade: 2,
    data: DateTime.now().subtract(Duration(days: 1)),
  ),
  Chamado(
    titulo: "Computador lento",
    descricao: "O computador está muito lento",
    status: "fechado",
    prioridade: 1,
    data: DateTime.now().subtract(Duration(days: 2)),
  ),
];
