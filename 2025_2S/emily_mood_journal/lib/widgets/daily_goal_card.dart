import 'package:flutter/material.dart';
import '../services/mood_storage.dart';

class DailyGoalCard extends StatefulWidget {
  const DailyGoalCard({super.key});

  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard> {
  bool _isGoalEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoalStatus();
  }

  Future<void> _loadGoalStatus() async {
    final isEnabled = await MoodStorage.getDailyGoal();
    setState(() {
      _isGoalEnabled = isEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleGoal() async {
    setState(() {
      _isGoalEnabled = !_isGoalEnabled;
    });
    await MoodStorage.setDailyGoal(_isGoalEnabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Meta diária',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Registre seu humor todos os dias para acompanhar seu bem-estar e identificar padrões.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _isGoalEnabled,
                  onChanged: (_) => _toggleGoal(),
                ),
                const SizedBox(width: 8),
                Text(
                  _isGoalEnabled ? 'Ativada' : 'Desativada',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _isGoalEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

