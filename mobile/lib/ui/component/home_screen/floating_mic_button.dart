import 'package:flutter/material.dart';

class FloatingMicButton extends StatelessWidget {
  const FloatingMicButton({
    required this.onLongPressStart,
    required this.onLongPressEnd,
    super.key,
  });

  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF2E9B59),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.mic_none_rounded, size: 34, color: Colors.white),
        ),
      ),
    );
  }
}
