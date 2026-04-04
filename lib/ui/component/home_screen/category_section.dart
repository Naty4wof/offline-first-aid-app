import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/ui/component/home_screen/section_title.dart';
import 'package:offline_first_aid_app/ui/screens/injury_screen.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_bloc.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_event.dart';
import 'package:offline_first_aid_app/features/guides/presentation/bloc/guide_state.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('የአደጋ ምድቦች'),
        const SizedBox(height: 10),

        BlocBuilder<GuideBloc, GuideState>(
          builder: (context, state) {
            if (state is GuideLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CategoryLoaded) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final category = state.categories[index];

                  final ui = _mapCategoryToUI(category.name);

                  return CategoryCard(
                    id: category.id,
                    title: category.name,
                    icon: ui.icon,
                    color: ui.color,
                  );
                },
              );
            }

            if (state is GuideError) {
              return Text(state.message);
            }

            return const SizedBox();
          },
        ),
      ],
    );
  }

  CategoryUI _mapCategoryToUI(String name) {
    switch (name) {
      case 'ደም መፍሰስ':
      case 'የደም መደምሰስ':
        return const CategoryUI(
          icon: Icons.bloodtype_rounded,
          color: Color(0xFFFFE8E8),
        );

      case 'ቃጠሎ':
        return const CategoryUI(
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFFF1E5),
        );

      case 'ስብራት':
        return const CategoryUI(
          icon: Icons.healing_rounded,
          color: Color(0xFFE9F4FF),
        );

      case 'መታፈን':
        return const CategoryUI(
          icon: Icons.air_rounded,
          color: Color(0xFFE9F8EE),
        );

      default:
        return const CategoryUI(
          icon: Icons.medical_services_rounded,
          color: Color(0xFFEFF3F6),
        );
    }
  }
}

class CategoryUI {
  final IconData icon;
  final Color color;

  const CategoryUI({required this.icon, required this.color});
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    super.key,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final guideBloc = context.read<GuideBloc>();

          // Remove focus from any input (prevents keyboard from re-appearing on return)
          // FocusScope.of(context).unfocus();

          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value:
                        guideBloc, // reuse existing bloc captured from outer context
                    child: InjuryScreen(categoryId: id, categoryName: title),
                  ),
                ),
              )
              .then((_) {
                // When returning from the Injury screen, ensure categories are shown again
                guideBloc.add(LoadCategories());
                // also ensure no input keeps focus after returning
                FocusScope.of(context).unfocus();
              });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1B2A2E), size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF152126),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
