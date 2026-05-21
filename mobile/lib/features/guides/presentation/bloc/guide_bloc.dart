import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_first_aid_app/core/services/storage_service.dart';
// import '../../data/models/category_model.dart';
// import '../../data/models/guide_model.dart';
import '../../data/models/injury_model.dart';
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
        final words = q
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

        // 1. Categories
        final matchedCategories = categories
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

        // 2. Injuries with scoring
        final Map<InjuryModel, double> injuryScores = {};
        for (final i in injuries) {
          double score = 0;
          final title = i.title.toLowerCase();

          if (title == q)
            score += 15;
          else if (title.contains(q))
            score += 8;

          for (final k in i.keywords) {
            final kw = k.toLowerCase();
            if (kw == q)
              score += 10;
            else if (kw.contains(q))
              score += 5;
            for (final w in words) {
              if (kw.contains(w)) score += 2;
            }
          }
          if (score > 0) injuryScores[i] = score;
        }

        final matchedInjuries = injuryScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // 3. Guides
        final matchedGuides = guides.where((g) {
          final inTitle = g.title.toLowerCase().contains(q);
          final inSteps = g.steps.any((s) => s.toLowerCase().contains(q));
          return inTitle || inSteps;
        }).toList();

        emit(
          SearchLoaded(
            categories: matchedCategories,
            injuries: matchedInjuries.map((e) => e.key).toList(),
            guides: matchedGuides,
          ),
        );
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });

    on<ToggleFavorite>((event, emit) async {
      try {
        await StorageService.instance.toggleFavorite(event.injuryId);
        // Re-emit current state to trigger UI update
        final currentState = state;
        if (currentState is GuideLoaded) {
          emit(GuideLoaded(currentState.guides));
        } else if (currentState is InjuryLoaded) {
          emit(InjuryLoaded(currentState.injuries));
        } else if (currentState is FavoritesLoaded) {
          add(LoadFavorites()); // Refresh favorites list
        }
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });

    on<LoadFavorites>((event, emit) async {
      emit(GuideLoading());
      try {
        final favorites = StorageService.instance.getFavorites();
        final allInjuries = await repository.getInjuries();
        final favoriteInjuries = allInjuries
            .where((i) => favorites.contains(i.id))
            .toList();
        emit(FavoritesLoaded(favoriteInjuries));
      } catch (e) {
        emit(GuideError(e.toString()));
      }
    });
  }
}
