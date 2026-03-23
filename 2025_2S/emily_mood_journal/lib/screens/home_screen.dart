import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/mood_entry.dart';
// import '../services/mood_storage.dart';
// imports comentados pois o conteúdo original foi substituído pela página de lista
// import '../widgets/mood_selector.dart';
// import '../widgets/mood_card.dart';
// import '../widgets/daily_goal_card.dart';
import '../widgets/app_drawer.dart';
import '../features/daily_goals/presentation/daily_goal_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // List<MoodEntry> _moodEntries = [];
  // When the home screen was adapted to show the DailyGoal list, the
  // loading flag was left as `true`, causing the CircularProgressIndicator
  // to be shown permanently. Set to false so the `DailyGoalListPage` is
  // rendered.
  bool _isLoading = false;
  // bool _hasEntryToday = false;

  @override
  void initState() {
    super.initState();
    // _loadMoodEntries(); // chamada comentada pois a home foi substituída pela página de lista
  }

  /*
  Future<void> _loadMoodEntries() async {
    setState(() {
      _isLoading = true;
    });

    final entries = await MoodStorage.getMoodEntries();
    final hasEntryToday = await MoodStorage.hasEntryToday();

    setState(() {
      _moodEntries = entries;
      _hasEntryToday = hasEntryToday;
      _isLoading = false;
    });
  }
  */

  // Future<void> _onMoodSelected(MoodType mood) async { ... } // comentado

  // Future<void> _onMoodDeleted(String id) async { ... } // comentado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Daily Goal'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : /* Conteúdo original comentado:
          SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Como você está se sentindo hoje?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MoodSelector(
                    onMoodSelected: _onMoodSelected,
                    hasEntryToday: _hasEntryToday,
                  ),
                  const SizedBox(height: 24),
                  const DailyGoalCard(),
                  const SizedBox(height: 24),
                  if (_moodEntries.isNotEmpty) ...[
                    const Text(
                      'Entradas recentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._moodEntries.take(3).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MoodCard(
                          entry: entry,
                          onDelete: () => _onMoodDeleted(entry.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          */
          // Substituído pelo layout da lista de Daily Goals criado
          const DailyGoalListPage(entity: 'Daily Goal'),
    );
  }
}
