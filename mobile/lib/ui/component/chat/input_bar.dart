import 'package:flutter/material.dart';
import 'circle_action_button.dart';

class InputBar extends StatelessWidget {
  const InputBar({
    required this.controller,
    required this.onSend,
    required this.onMicTap,
    super.key,
  });

  final TextEditingController controller;
  final void Function(String) onSend;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'የአደጋ ሁኔታ ይጻፉ...',
                filled: true,
                fillColor: const Color(0xFFF1F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleActionButton(
            icon: Icons.send_rounded,
            background: const Color(0xFFE8F4ED),
            iconColor: const Color(0xFF2E9B59),
            onTap: () => onSend(controller.text),
          ),
        ],
      ),
    );
  }
}
