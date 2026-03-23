import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../data/sample_data.dart';

class TaskService extends ChangeNotifier {
  static const String _tasksKey = 'taskflow_tasks';
  final List<Task> _tasks = [];
  bool _isInitialized = false;
  
  TaskService() {
    initializeTasks();
  }

  Future<void> initializeTasks() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    
    if (tasksJson != null) {
      // Carrega tarefas salvas
      try {
        final List<dynamic> jsonList = jsonDecode(tasksJson);
        _tasks.clear();
        _tasks.addAll(jsonList.map((json) => Task.fromJson(json)));
        print('📋 Carregadas ${_tasks.length} tarefas salvas');
      } catch (e) {
        print('❌ Erro ao carregar tarefas: $e');
        _tasks.clear();
      }
    }
    // Para primeira vez, não cria tarefas automaticamente
    // Isso permite uma experiência limpa para novos usuários
    
    _isInitialized = true;
    notifyListeners();
  }
  
  // Método separado para criar tarefas de exemplo (opcional)
  Future<void> loadSampleTasks() async {
    _tasks.clear();
    _tasks.addAll(SampleData.getSampleTasks());
    await _saveTasks();
    print('📋 Carregadas ${_tasks.length} tarefas de exemplo');
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
      await prefs.setString(_tasksKey, tasksJson);
      print('💾 Tarefas salvas: ${_tasks.length} itens');
    } catch (e) {
      print('❌ Erro ao salvar tarefas: $e');
    }
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();

  int get totalTasks => _tasks.length;

  int get completedTasksCount => completedTasks.length;

  int get pendingTasksCount => pendingTasks.length;

  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return completedTasksCount / totalTasks;
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere((task) => task.id == taskId);
    task.isCompleted = !task.isCompleted;
    await _saveTasks();
    notifyListeners();
  }

  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;
    
    return _tasks.where((task) =>
      task.title.toLowerCase().contains(query.toLowerCase()) ||
      task.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<void> clearCompletedTasks() async {
    _tasks.removeWhere((task) => task.isCompleted);
    await _saveTasks();
    notifyListeners();
  }

  // Método para limpar todas as tarefas (útil para desenvolvimento)
  Future<void> clearAllTasks() async {
    _tasks.clear();
    await _saveTasks();
    notifyListeners();
  }

  // Getter para verificar se o serviço foi inicializado
  bool get isInitialized => _isInitialized;

  // Métodos para persistência local
  String toJson() {
    return jsonEncode(_tasks.map((task) => task.toJson()).toList());
  }

  Future<void> fromJson(String jsonString) async {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    _tasks.clear();
    _tasks.addAll(jsonList.map((json) => Task.fromJson(json)));
    await _saveTasks();
    notifyListeners();
  }
}