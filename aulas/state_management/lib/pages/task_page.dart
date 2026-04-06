import 'package:flutter/material.dart';
import 'package:state_management/data/task_mock_data.dart';
import 'package:state_management/models/task.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  int _favoriteCount = 0;

  void toogleTaskStatus(Task task) {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    final index = mockTasks.indexWhere((t) => t.taskId == task.taskId);
    if (index != -1) {
      setState(() {
        mockTasks[index] = updatedTask;
      });
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Manager')),
      body: Column(
        children: [
          Container(
            color: Colors.yellow,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: mockTasks
                    .map((t) => Chip(label: Text(t.title)))
                    .toList(),
              ),
            ),
          ),
          Text('Total de favoritos: $_favoriteCount'),
          Expanded(
            child: ListView.builder(
              itemCount: mockTasks.length,
              itemBuilder: (context, index) {
                final task = mockTasks[index];
                return Column(
                  children: [
                    ListTile(
                      mouseCursor: SystemMouseCursors.click,
                      title: Text(task.title),
                      subtitle: Text(task.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              task.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: task.isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              // Implement favorite toggle logic here
                              toogleTaskFavorite(task);
                            },
                          ),
                          Visibility(
                            visible: task.isCompleted,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          // if (task.isCompleted)
                          //   Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                      onLongPress: () {
                        doTileLongPress(task, context);
                      },
                      onTap: () {
                        debugPrint(
                          'Tapped on task: ${task.title}',
                        ); // Debug print
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Divider(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void doTileLongPress(Task task, BuildContext context) {
    if (task.isCompleted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Reverter status?'),
            content: Text(
              'Do you want to mark "${task.title}" as not completed?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  toogleTaskStatus(task);
                  Navigator.of(context).pop();
                  showSnackBar(
                    context,
                    'Task "${task.title}" marked as not completed!',
                  );
                },
                child: Text('Reverter'),
              ),
            ],
          );
        },
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     backgroundColor: Colors.yellow,
      //     content: Text(
      //       'Task "${task.title}" is already completed!',
      //       style: TextStyle(color: Colors.black, fontSize: 24),
      //     ),
      //     action: SnackBarAction(
      //       backgroundColor: Colors.white,
      //       label: 'Reverter?',
      //       onPressed: () {
      //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
      //       },
      //       textColor: Colors.black,
      //     ),
      //   ),
      // );
    } else {
      toogleTaskStatus(task);
      showSnackBar(context, 'Task "${task.title}" marked as completed!');
    }
  }

  void toogleTaskFavorite(Task task) {
    final updatedTask = task.copyWith(isFavorite: !task.isFavorite);
    final index = mockTasks.indexWhere((t) => t.taskId == task.taskId);
    if (index != -1) {
      setState(() {
        mockTasks[index] = updatedTask;
        _favoriteCount += updatedTask.isFavorite ? 1 : -1;
      });
    }
  }
}
