abstract class GuideEvent {}

class LoadGuides extends GuideEvent {}

class LoadCategories extends GuideEvent {}

class LoadInjuriesByCategory extends GuideEvent {
  final String categoryId;

  LoadInjuriesByCategory(this.categoryId);
}

class LoadGuidesByInjury extends GuideEvent {
  final String injuryId;

  LoadGuidesByInjury(this.injuryId);
}

class SearchQuery extends GuideEvent {
  final String query;

  SearchQuery(this.query);
}
