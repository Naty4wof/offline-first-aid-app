import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_state.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';
import 'package:offline_first_aid_app/ui/screens/injury_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guideBloc = context.read<GuideBloc>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: const Text('ምድቦች'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF132125),
        elevation: 0,
      ),
      body: BlocBuilder<GuideBloc, GuideState>(
        builder: (context, state) {
          if (state is GuideLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryLoaded) {
            final categories = state.categories;

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = categories[index];
                final ui = _mapCategoryToUI(c.name);

                return _CategoryCard(
                  name: c.name,
                  description: c.description,
                  ui: ui,
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: guideBloc,
                              child: InjuryScreen(
                                categoryId: c.id,
                                categoryName: c.name,
                              ),
                            ),
                          ),
                        )
                        .then((_) {
                          guideBloc.add(LoadCategories());
                          FocusScope.of(context).unfocus();
                        });
                  },
                );
              },
            );
          }

          if (state is GuideError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }

  CategoryUI _mapCategoryToUI(String name) {
    switch (name) {
      case 'ቃጠሎ':
        return const CategoryUI(Icons.local_fire_department, Color(0xFFFFF1EC));
      case 'ደም መፍሰስ':
        return const CategoryUI(Icons.bloodtype, Color(0xFFFFEEF0));
      case 'የመተንፈስ ችግኝ':
        return const CategoryUI(Icons.air, Color(0xFFEFF7F1));
      case 'ስብራት እና መጨናነቅ':
        return const CategoryUI(Icons.healing, Color(0xFFEAF3FF));
      case 'ቁስሎች እና መቁረጥ':
        return const CategoryUI(Icons.content_cut, Color(0xFFF2F6F8));
      case 'መመረዝ':
        return const CategoryUI(Icons.warning_amber_rounded, Color(0xFFFFF6E9));
      case 'መውደቅ':
        return const CategoryUI(Icons.person_outline, Color(0xFFF1F5F9));
      case 'የነፍሳት ንክሻ':
        return const CategoryUI(Icons.bug_report_outlined, Color(0xFFEFF8F4));
      default:
        return const CategoryUI(Icons.medical_services, Color(0xFFF3F6F9));
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String description;
  final CategoryUI ui;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.description,
    required this.ui,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ui.color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(ui.icon, color: const Color(0xFF132125), size: 22),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF132125),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5F6F75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3A8)),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryUI {
  final IconData icon;
  final Color color;

  const CategoryUI(this.icon, this.color);
}
