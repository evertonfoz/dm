class Event {
  String nome;
  DateTime horarioInicio;
  DateTime horarioFim;
  Duration duracao;
  List<String> checklist;
  int quantidadePessoas;

  Event({
    required this.nome,
    required this.horarioInicio,
    required this.horarioFim,
    required this.duracao,
    required this.checklist,
    required this.quantidadePessoas,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'horarioInicio': horarioInicio.toIso8601String(),
    'horarioFim': horarioFim.toIso8601String(),
    'duracao': duracao.inMinutes,
    'checklist': checklist,
    'quantidadePessoas': quantidadePessoas,
  };

  static Event fromJson(Map<String, dynamic> json) => Event(
    nome: json['nome'],
    horarioInicio: DateTime.parse(json['horarioInicio']),
    horarioFim: DateTime.parse(json['horarioFim']),
    duracao: Duration(minutes: json['duracao']),
    checklist: List<String>.from(json['checklist']),
    quantidadePessoas: json['quantidadePessoas'],
  );
}