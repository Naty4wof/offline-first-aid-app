import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    required this.onGuidesTap,
    required this.onChatTap,
    super.key,
  });

  final VoidCallback onGuidesTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) {
          onGuidesTap();
        } else if (index == 2) {
          onChatTap();
        }
      },
      selectedItemColor: const Color(0xFFE14949),
      unselectedItemColor: const Color(0xFF5B7078),
      selectedFontSize: 13,
      unselectedFontSize: 12,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'መነሻ'),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded),
          label: 'መመሪያዎች',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'ውይይት'),
      ],
    );
  }
}
