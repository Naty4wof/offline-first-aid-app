import '../../data/models/category_model.dart';
import '../../data/models/guide_model.dart';
import '../../data/models/injury_model.dart';

abstract class GuideState {}

class GuideInitial extends GuideState {}

class GuideLoading extends GuideState {}

class GuideLoaded extends GuideState {
  final List<GuideModel> guides;

  GuideLoaded(this.guides);
}

class CategoryLoaded extends GuideState {
  final List<CategoryModel> categories;

  CategoryLoaded(this.categories);
}

class GuideError extends GuideState {
  final String message;

  GuideError(this.message);
}

class InjuryLoaded extends GuideState {
  final List<InjuryModel> injuries;

  InjuryLoaded(this.injuries);
}

class SearchLoading extends GuideState {}

class SearchLoaded extends GuideState {
  final List<CategoryModel> categories;
  final List<InjuryModel> injuries;
  final List<GuideModel> guides;

  SearchLoaded({
    required this.categories,
    required this.injuries,
    required this.guides,
  });
}
