import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../theme/app_theme.dart';
import '../utils/accessibility_utils.dart';

class MoodSelector extends StatefulWidget {

  const MoodSelector({
    super.key,
    required this.onMoodSelected,
    required this.hasEntryToday,
  });
  final Function(MoodType) onMoodSelected;
  final bool hasEntryToday;

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  MoodType? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (widget.hasEntryToday) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.roseLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryRose.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryRose, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Você já registrou seu humor hoje!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryRose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Como você está se sentindo hoje?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodType.values.map((mood) {
                final isSelected = selectedMood == mood;
                return AccessibilityUtils.buildSemanticButton(
                  onPressed: () {
                    setState(() {
                      selectedMood = mood;
                    });
                    widget.onMoodSelected(mood);
                    AccessibilityUtils.announceToScreenReader(
                      context,
                      'Humor selecionado: ${mood.description}',
                    );
                  },
                  label: 'Selecionar humor ${mood.description}',
                  hint: 'Toque para selecionar este humor',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMood = mood;
                      });
                      widget.onMoodSelected(mood);
                    },
                    child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryRose.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryRose
                                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppTheme.primaryRose.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mood.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primaryRose : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  ),
                );
              }).toList(),
            ),
            if (selectedMood != null) ...[
              const SizedBox(height: 24),
              AccessibilityUtils.buildSemanticCard(
                label: 'Frase motivacional: ${selectedMood!.randomMotivationalQuote}',
                hint: 'Frase inspiradora baseada no seu humor selecionado',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryIndigo.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryIndigo,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedMood!.randomMotivationalQuote,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryIndigo,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

