import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/guide_repository.dart';
import 'guide_event.dart';
import 'guide_state.dart';

class GuideBloc extends Bloc<GuideEvent, GuideState> {
  final GuideRepository repository;

  GuideBloc(this.repository) : super(GuideInitial()) {
    on<LoadCategories>((event, emit) async {
      emit(GuideLoading());
      try {
        final categories = await repository.getCategories();
        emit(CategoryLoaded(categories));
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });
    on<LoadInjuriesByCategory>((event, emit) async {
      emit(GuideLoading());
      try {
        final injuries = await repository.getInjuriesByCategory(
          event.categoryId,
        );
        emit(InjuryLoaded(injuries));
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });
    on<LoadGuidesByInjury>((event, emit) async {
      emit(GuideLoading());
      try {
        final guides = await repository.getGuidesByInjury(event.injuryId);
        emit(GuideLoaded(guides));
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });
    on<SearchQuery>((event, emit) async {
      emit(SearchLoading());
      try {
        final categories = await repository.getCategories();
        final injuries = await repository.getInjuries();
        final guides = await repository.getGuides();

        final q = event.query.toLowerCase();

        final matchedCategories = categories
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

        final matchedInjuries = injuries.where((i) {
          return i.title.toLowerCase().contains(q) ||
              i.keywords.any((k) => k.toLowerCase().contains(q));
        }).toList();

        final matchedGuides = guides.where((g) {
          final inTitle = g.title.toLowerCase().contains(q);
          final inSteps = g.steps.any((s) => s.toLowerCase().contains(q));
          return inTitle || inSteps;
        }).toList();

        emit(
          SearchLoaded(
            categories: matchedCategories,
            injuries: matchedInjuries,
            guides: matchedGuides,
          ),
        );
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });
  }
}
