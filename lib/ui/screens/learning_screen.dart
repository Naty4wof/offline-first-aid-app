import 'package:flutter/material.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF2E9B59);
    final accent = const Color(0xFF3B82F6);

    const categories = ['የደም ማቆጣጠሪያ', 'ቃጠሎ', 'ስብራት', 'መታፈን'];

    final courses = [
      {'title': 'የመደምሰስ መቆጣጠሪያ', 'progress': 0.4},
      {'title': 'የቃጠሎ ማቀዝቀዣ', 'progress': 0.25},
      {'title': 'የመታፈን መደረጃ', 'progress': 0.6},
    ];

    final continuing = [
      {'title': 'የደም መደምሰስ — ምዕራፍ 2', 'progress': 0.35},
      {'title': 'የቃጠሎ ማቀዝቀዣ — ቀን 1', 'progress': 0.7},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('የትምህርት ማዕከል'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF132125),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7FAFB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            // Search
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ፈልግ...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: const Color(0xFFF2F6F8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Categories
            const Text(
              'ምድቦች',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final label = categories[index];
                  return _CategoryCard(
                    label: label,
                    color: index.isEven
                        ? const Color.fromRGBO(59, 130, 246, 0.12)
                        : const Color.fromRGBO(46, 155, 89, 0.12),
                    iconColor: index.isEven ? accent : primary,
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Courses / Modules
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ኮርሶች',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                TextButton(onPressed: () {}, child: const Text('ሁሉን እይ')),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: courses.map((c) {
                final title = c['title'] as String;
                final progress = c['progress'] as double;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              color: primary,
                              backgroundColor: const Color.fromRGBO(
                                46,
                                155,
                                89,
                                0.12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Continue Learning
            const Text(
              'ቀጥለህ የምትማሩ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: continuing.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = continuing[index];
                  final title = item['title'] as String;
                  final progress = item['progress'] as double;
                  return _ContinueCard(
                    title: title,
                    progress: progress,
                    color: primary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.folder_rounded, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.title,
    required this.progress,
    required this.color,
  });

  final String title;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: color,
                      backgroundColor: const Color.fromRGBO(46, 155, 89, 0.12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
