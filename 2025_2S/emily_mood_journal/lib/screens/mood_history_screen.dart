import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/mood_storage.dart';
import '../widgets/mood_card.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoodEntries();
  }

  Future<void> _loadMoodEntries() async {
    setState(() {
      _isLoading = true;
    });

    final entries = await MoodStorage.getMoodEntries();
    setState(() {
      _moodEntries = entries;
      _isLoading = false;
    });
  }

  Future<void> _onMoodDeleted(String id) async {
    await MoodStorage.deleteMoodEntry(id);
    await _loadMoodEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Histórico de Humor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _moodEntries.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_neutral,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma entrada encontrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Comece registrando seu humor na tela principal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _moodEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _moodEntries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MoodCard(
                        entry: entry,
                        onDelete: () => _onMoodDeleted(entry.id),
                      ),
                    );
                  },
                ),
    );
  }
}

