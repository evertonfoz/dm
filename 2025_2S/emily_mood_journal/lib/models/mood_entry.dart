import 'package:intl/intl.dart';
import 'dart:math';

enum MoodType {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
}

extension MoodTypeExtension on MoodType {
  String get emoji {
    switch (this) {
      case MoodType.veryHappy:
        return '😄';
      case MoodType.happy:
        return '😊';
      case MoodType.neutral:
        return '😐';
      case MoodType.sad:
        return '😔';
      case MoodType.verySad:
        return '😢';
    }
  }

  String get description {
    switch (this) {
      case MoodType.veryHappy:
        return 'Muito feliz';
      case MoodType.happy:
        return 'Feliz';
      case MoodType.neutral:
        return 'Neutro';
      case MoodType.sad:
        return 'Triste';
      case MoodType.verySad:
        return 'Muito triste';
    }
  }

  double get value {
    switch (this) {
      case MoodType.veryHappy:
        return 5.0;
      case MoodType.happy:
        return 4.0;
      case MoodType.neutral:
        return 3.0;
      case MoodType.sad:
        return 2.0;
      case MoodType.verySad:
        return 1.0;
    }
  }

  List<String> get motivationalQuotes {
    switch (this) {
      case MoodType.veryHappy:
        return [
          'Que energia incrível! Continue assim! 🌟',
          'Sua felicidade é contagiante! 😄',
          'Dias como hoje são especiais! ✨',
          'Você está brilhando! Continue! 🌈',
          'Que momento maravilhoso! 🎉',
          'Sua alegria ilumina tudo ao redor! ☀️',
        ];
      case MoodType.happy:
        return [
          'Que bom te ver bem! 😊',
          'Pequenos momentos de felicidade fazem toda diferença! 🌸',
          'Continue cultivando essa energia positiva! 💫',
          'Sua serenidade é inspiradora! 🌺',
          'Momentos como este são preciosos! 💎',
          'Que bom quando tudo flui naturalmente! 🌊',
        ];
      case MoodType.neutral:
        return [
          'Está tudo bem sentir-se assim! 🤗',
          'Equilíbrio é uma virtude! ⚖️',
          'Dias neutros também têm seu valor! 🌤️',
          'Acalmar-se é um superpoder! 🧘',
          'Respire fundo, você está bem! 💨',
          'A serenidade traz clareza! 🔮',
        ];
      case MoodType.sad:
        return [
          'É normal sentir-se assim às vezes! 💙',
          'Permita-se sentir, mas não se perca! 🌧️',
          'Chuva passa, e o sol sempre volta! ☀️',
          'Você é mais forte do que imagina! 💪',
          'Dias difíceis também passam! 🌈',
          'Cuide-se com carinho hoje! 🤗',
        ];
      case MoodType.verySad:
        return [
          'Você não está sozinho(a)! 🤝',
          'É corajoso reconhecer seus sentimentos! 💜',
          'Permita-se chorar, mas não desista! 💧',
          'Amanhã é uma nova oportunidade! 🌅',
          'Você é amado(a) e importante! ❤️',
          'Peça ajuda se precisar, está tudo bem! 🆘',
        ];
    }
  }

  String get randomMotivationalQuote {
    final quotes = motivationalQuotes;
    return quotes[Random().nextInt(quotes.length)];
  }
}

class MoodEntry {

  MoodEntry({
    required this.id,
    required this.mood,
    required this.timestamp,
    this.note,
    this.tags = const [],
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      mood: MoodType.values[json['mood']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      note: json['note'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
  final String id;
  final MoodType mood;
  final DateTime timestamp;
  final String? note;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'note': note,
      'tags': tags,
    };
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(timestamp);
  }
}

