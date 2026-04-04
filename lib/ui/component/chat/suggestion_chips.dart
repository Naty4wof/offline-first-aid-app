import 'package:flutter/material.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({required this.labels, required this.onTap, super.key});

  final List<String> labels;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        return ActionChip(
          onPressed: () => onTap(label),
          label: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          side: const BorderSide(color: Color(0xFFD8E1E6)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        );
      }).toList(),
    );
  }
}
