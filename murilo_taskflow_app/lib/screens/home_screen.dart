import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/preferences_service.dart';
import '../services/photo_service.dart';
// Conditional import: on web use the JS getUserMedia helper. The stub returns
// null on non-web so imports are safe across platforms.
import '../services/photo_service_web_stub.dart'
    if (dart.library.html) '../services/photo_service_web.dart'
    as web_camera;
import '../services/io.dart' show isDesktop;
import '../widgets/task_card.dart';
import '../widgets/user_avatar.dart';
import 'add_edit_task_screen.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('TaskFlow'),
        centerTitle: true,
        actions: [
          // Avatar do usuário no AppBar
          Consumer<PreferencesService>(
            builder: (context, prefsService, child) {
              return Padding(
                padding: const EdgeInsets.only(
                  right: 8.0,
                ), // Aumentado de 4 para 8
                child: UserAvatar(
                  photoPath: prefsService.userPhotoPath,
                  userName: prefsService.userName,
                  radius:
                      16, // Aumentado de 14 para 16 para melhor visibilidade
                  onTap: () => _showPhotoOptions(context),
                  showBorder: true,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            padding: const EdgeInsets.all(8), // Reduzido de 12 para 8
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ), // Adicionado constraints para garantir tamanho mínimo
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            120,
          ), // Aumentado de 110 para 120
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  8,
                ), // Reduzido padding top de 8 para 4
                child: Container(
                  height: 44, // Reduzido de 48 para 44
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar tarefas...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ), // Reduzido vertical padding
                      isDense: true, // Adiciona densidade para reduzir altura
                    ),
                  ),
                ),
              ),
              Container(
                height: 48, // Altura fixa para o TabBar
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Pendentes'),
                    Tab(text: 'Concluídas'),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          return Column(
            children: [
              _buildStatsCard(taskService),
              _buildFirstStepsCard(taskService),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(taskService.searchTasks(_searchQuery)),
                    _buildTaskList(
                      taskService
                          .searchTasks(_searchQuery)
                          .where((task) => !task.isCompleted)
                          .toList(),
                    ),
                    _buildTaskList(
                      taskService
                          .searchTasks(_searchQuery)
                          .where((task) => task.isCompleted)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(TaskService taskService) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatItem(
                  'Total',
                  taskService.totalTasks.toString(),
                  Icons.assignment,
                  const Color(0xFF3B82F6), // Blue com melhor contraste
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Pendentes',
                  taskService.pendingTasksCount.toString(),
                  Icons.pending,
                  const Color(0xFFF59E0B), // Orange com melhor contraste
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Concluídas',
                  taskService.completedTasksCount.toString(),
                  Icons.check_circle,
                  const Color(0xFF10B981), // Green com melhor contraste
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (taskService.totalTasks > 0) ...[
              Text(
                'Progresso: ${(taskService.completionPercentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: taskService.completionPercentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.withValues(alpha: 0.8), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstStepsCard(TaskService taskService) {
    // Só mostra se o usuário tem menos de 3 tarefas criadas
    if (taskService.totalTasks >= 3) {
      return const SizedBox.shrink();
    }

    final tasksRemaining = 3 - taskService.totalTasks;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
              Theme.of(context).primaryColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Primeiros Passos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Crie suas primeiras $tasksRemaining tarefas do dia para começar a organizar sua produtividade!',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: taskService.totalTasks / 3,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 6,
              ),

              const SizedBox(height: 12),

              Text(
                '${taskService.totalTasks}/3 tarefas criadas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calcula o tamanho do ícone baseado na altura disponível
          final double availableHeight = constraints.maxHeight;
          final double iconSize = availableHeight > 150 ? 36 : 24;
          final double fontSize = availableHeight > 150 ? 14 : 12;
          final double smallFontSize = availableHeight > 150 ? 12 : 10;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: availableHeight > 100
                        ? 80
                        : availableHeight * 0.8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: iconSize,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: availableHeight > 150 ? 8 : 4),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Nenhuma tarefa encontrada'
                            : 'Nenhuma tarefa aqui',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: availableHeight > 150 ? 4 : 2),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Tente outro termo'
                            : 'Adicione uma tarefa',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onToggle: () => _toggleTask(task.id),
          onEdit: () => _editTask(task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  void _addNewTask() async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
    );

    if (result != null && mounted) {
      await context.read<TaskService>().addTask(result);
    }
  }

  void _editTask(Task task) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );

    if (result != null && mounted) {
      await context.read<TaskService>().updateTask(result);
    }
  }

  void _toggleTask(String taskId) async {
    await context.read<TaskService>().toggleTaskCompletion(taskId);
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: Text('Tem certeza que deseja excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<TaskService>().deleteTask(task.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  // ========== DRAWER COM AVATAR ==========

  Widget _buildDrawer(BuildContext context) {
    final prefsService = context.watch<PreferencesService>();
    final userName = prefsService.userName;
    final userPhotoPath = prefsService.userPhotoPath;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200, // Aumentado de 180 para 200
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false, // Remove padding inferior do SafeArea
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  8,
                  4,
                  8,
                  8,
                ), // Padding assimétrico: menor no topo
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar com espaçamento adequado
                    Center(
                      child: UserAvatar(
                        photoPath: userPhotoPath,
                        userName: userName,
                        radius: 24, // Reduzido de 26 para 24
                        onTap: () => _showPhotoOptions(context),
                        showBorder: true,
                      ),
                    ),
                    const SizedBox(height: 6), // Reduzido de 8 para 6
                    // Nome do usuário
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14, // Reduzido de 15 para 14
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    // Texto de instrução
                    Text(
                      userPhotoPath != null
                          ? 'Toque para alterar foto'
                          : 'Toque para adicionar foto',
                      style: const TextStyle(
                        fontSize: 9, // Reduzido de 10 para 9
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar Nome'),
            onTap: () => _showEditNameDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Gerenciar Foto'),
            onTap: () => _showPhotoOptions(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            onTap: () {
              Navigator.of(context).pop();
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    final prefsService = context.read<PreferencesService>();
    final hasPhoto = prefsService.userPhotoPath != null;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sua foto neste dispositivo. Você pode removê-la quando quiser.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sua foto será salva apenas localmente neste dispositivo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            // Opção de câmera para todas plataformas
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(isDesktop ? 'Tirar Foto (Webcam)' : 'Tirar Foto'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(isDesktop ? 'Escolher Foto' : 'Escolher da Galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remover Foto',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeletePhoto(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photoService = PhotoService();
    final parentContext = context;

    if (!mounted) return;

    // Web + Câmera: use browser getUserMedia flow (no file picker)
    if (kIsWeb && source == ImageSource.camera) {
      if (!mounted) return;
      // Show a short loading dialog while the browser asks for camera permission
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final dataUrl = await web_camera.pickImageFromWebCamera();
        if (!mounted) return;
        Navigator.of(parentContext).pop(); // remove loading

        if (dataUrl != null) {
          await parentContext.read<PreferencesService>().setUserPhotoPath(
            dataUrl,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Foto salva com sucesso!')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(
            parentContext,
          ).showSnackBar(const SnackBar(content: Text('Captura cancelada')));
        }
      } catch (e) {
        if (!mounted) return;
        try {
          Navigator.of(parentContext).pop();
        } catch (_) {}
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Erro ao usar a câmera web: $e')),
        );
      }

      return;
    }

    // Desktop + Câmera: usa CameraScreen (flutter_lite_camera)
    if (isDesktop && source == ImageSource.camera) {
      try {
        final capturedPath = await Navigator.of(
          parentContext,
        ).push<String>(MaterialPageRoute(builder: (_) => const CameraScreen()));

        if (!mounted) return;

        if (capturedPath != null) {
          // Comprimir e salvar
          showDialog(
            context: parentContext,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          final compressedPath = await photoService.compressImage(capturedPath);
          String? savedPath;
          if (compressedPath != null) {
            savedPath = await photoService.savePhoto(compressedPath);
          }

          if (!mounted) return;
          Navigator.of(parentContext).pop(); // Remove loading

          if (savedPath != null) {
            await parentContext.read<PreferencesService>().setUserPhotoPath(
              savedPath,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(content: Text('Foto salva com sucesso!')),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(content: Text('Erro ao processar foto')),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          parentContext,
        ).showSnackBar(SnackBar(content: Text('Erro ao capturar foto: $e')));
      }
      return;
    }

    // Mobile ou Desktop+Galeria: usa ImagePicker
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final photoPath = await photoService.pickCompressAndSave(source);

      if (!mounted) return;
      Navigator.of(parentContext).pop();

      if (photoPath != null) {
        await parentContext.read<PreferencesService>().setUserPhotoPath(
          photoPath,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Foto salva com sucesso!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Nenhuma foto foi selecionada')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(parentContext).pop();
      ScaffoldMessenger.of(
        parentContext,
      ).showSnackBar(SnackBar(content: Text('Erro ao processar foto: $e')));
    }
  }

  void _confirmDeletePhoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Foto'),
        content: const Text(
          'Tem certeza que deseja remover sua foto de perfil?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePhoto();
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto() async {
    final photoService = PhotoService();
    final success = await photoService.deletePhoto();

    if (!mounted) return;

    if (success) {
      await context.read<PreferencesService>().setUserPhotoPath(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto removida com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao remover foto')));
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final prefsService = context.read<PreferencesService>();
    final controller = TextEditingController(text: prefsService.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Seu nome',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await prefsService.setUserName(newName);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome atualizado!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TaskFlow',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.task_alt, size: 48),
      children: [
        const Text(
          'Um aplicativo de gerenciamento de tarefas desenvolvido em Flutter.',
        ),
        const SizedBox(height: 8),
        const Text('© 2025 TaskFlow'),
      ],
    );
  }
}
