class Compromisso {
  String titulo;
  DateTime data;
  bool concluido;

  Compromisso({
    required this.titulo,
    required this.data,
    this.concluido = false,
  });
}
