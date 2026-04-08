import 'package:flutter/material.dart';

class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
