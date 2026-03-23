import '../models/task.dart';

class SampleData {
  static List<Task> getSampleTasks() {
    final now = DateTime.now();
    
    return [
      Task(
        id: '1',
        title: 'Revisar projeto TaskFlow',
        description: 'Fazer uma revisão completa do código e documentação',
        priority: TaskPriority.high,
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
      ),
      Task(
        id: '2',
        title: 'Comprar ingredientes para jantar',
        description: 'Ir ao supermercado e comprar os ingredientes necessários',
        priority: TaskPriority.medium,
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now,
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'Ler artigo sobre Flutter',
        description: 'Ler o novo artigo sobre boas práticas em Flutter',
        priority: TaskPriority.low,
        createdAt: now.subtract(const Duration(hours: 3)),
        isCompleted: true,
      ),
      Task(
        id: '4',
        title: 'Exercitar-se',
        description: '30 minutos de caminhada no parque',
        priority: TaskPriority.medium,
        createdAt: now.subtract(const Duration(hours: 1)),
        dueDate: now.add(const Duration(hours: 2)),
        isCompleted: false,
      ),
    ];
  }
}