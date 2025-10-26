import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  activeColor: Theme.of(context).primaryColor,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isCompleted
                              ? Colors.grey
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: task.isCompleted
                                ? Colors.grey
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(task.priority),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.priority.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriorityColor(task.priority),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (task.dueDate != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _getDueDateColor(task.dueDate!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDueDateColor(task.dueDate!),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red; // Vencida
    } else if (difference == 0) {
      return Colors.orange; // Vence hoje
    } else if (difference <= 3) {
      return Colors.amber; // Vence em poucos dias
    } else {
      return Colors.grey; // Ainda tem tempo
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Vencida';
    } else if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Amanhã';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}