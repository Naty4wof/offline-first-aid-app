import 'package:flutter/material.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/section_title.dart';

class RecentSection extends StatelessWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context) {
    const guides = <GuideItem>[
      GuideItem(
        title: 'የመደምሰስ መቆጣጠሪያ እርምጃዎች',
        subtitle: 'የመደምሰስ መቆጣጠሪያ እርምጃዎች',
        icon: Icons.bookmark_rounded,
      ),
      GuideItem(
        title: 'የቃጠሎ መቀዝቀዣ መመሪያ',
        subtitle: 'የቃጠሎ ማቀዝቀዣ መመሪያ',
        icon: Icons.history_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('የቅርብ ጊዜ / የተወደዱ መመሪያዎች'),
        const SizedBox(height: 10),
        for (final guide in guides)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(guide.icon, color: const Color(0xFF1F2D32)),
                ),
                title: Text(
                  guide.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(guide.subtitle),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
              ),
            ),
          ),
      ],
    );
  }
}

class GuideItem {
  const GuideItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
