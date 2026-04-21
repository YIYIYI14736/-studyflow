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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('还没有科目，请先添加'),
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
