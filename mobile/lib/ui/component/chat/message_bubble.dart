import 'package:flutter/material.dart';
import 'chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFE14949) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: !isUser
              ? Border.all(color: const Color(0xFFE2E8EC))
              : Border.all(color: const Color(0xFFE14949)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.isImportant)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'አስፈላጊ መመሪያ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 231, 114, 114),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 17,
                height: 1.4,
                color: isUser ? Colors.white : const Color(0xFF1A272C),
                fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
