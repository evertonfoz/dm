class Task {
  final String taskId;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isFavorite;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isFavorite = false,
  });

  Task copyWith({
    String? taskId,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isFavorite,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
