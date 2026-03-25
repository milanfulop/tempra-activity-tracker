import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/time_slot_provider.dart';

class ActivityBottomSheet extends StatefulWidget {
  const ActivityBottomSheet({super.key});

  @override
  State<ActivityBottomSheet> createState() => _ActivityBottomSheetState();
}

class _ActivityBottomSheetState extends State<ActivityBottomSheet> {
  final _activityController = TextEditingController();
  String _selectedCategory = 'Work';
  Color _selectedColor = Colors.blue;

  final _categories = [
    ('Work',     Colors.blue),
    ('Exercise', Colors.green),
    ('Rest',     Colors.purple),
    ('Social',   Colors.orange),
    ('Wasted',   Colors.red),
  ];

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TimeSlotProvider>();
    final count = provider.selectedIndices.length;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count slot${count > 1 ? 's' : ''} selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // ── activity name ──────────────────────────────────────────────
          TextField(
            controller: _activityController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Activity name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // ── category chips ─────────────────────────────────────────────
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat.$1;
              return ChoiceChip(
                label: Text(cat.$1),
                selected: isSelected,
                selectedColor: cat.$2.withOpacity(0.3),
                onSelected: (_) => setState(() {
                  _selectedCategory = cat.$1;
                  _selectedColor = cat.$2;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── save button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_activityController.text.trim().isEmpty) return;
                provider.applyActivity(
                  activity: _activityController.text.trim(),
                  category: _selectedCategory,
                  color: _selectedColor.withOpacity(0.2),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}