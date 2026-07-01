import 'package:flutter/material.dart';
import 'package:studyflow/models/models.dart';

class SubjectSelector extends StatelessWidget {
  final List<Subject> subjects;
  final String? selectedSubjectId;
  final Function(Subject?) onSubjectSelected;

  const SubjectSelector({
    super.key,
    required this.subjects,
    this.selectedSubjectId,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined,
                    size: 40,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('还没有科目，请先到首页添加',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.map((subject) {
        final isSelected = subject.id == selectedSubjectId;
        return ChoiceChip(
          label: Text(subject.name),
          selected: isSelected,
          onSelected: (_) => onSubjectSelected(isSelected ? null : subject),
          avatar: CircleAvatar(
            backgroundColor: _parseColor(subject.color),
            child: Text(
              subject.name[0],
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _parseColor(String? color) {
    if (color == null) return Colors.blue;
    try {
      return Color(int.parse(color));
    } catch (_) {
      return Colors.blue;
    }
  }
}
