class InjuryModel {
  final String id;
  final String categoryId;
  final String title;
  final String severity;
  final List<String> keywords;

  InjuryModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.severity,
    required this.keywords,
  });

  factory InjuryModel.fromJson(Map<String, dynamic> json) {
    return InjuryModel(
      id: json['id'],
      categoryId: json['categoryId'],
      title: json['title'],
      severity: json['severity'],
      keywords: List<String>.from(json['keywords']),
    );
  }
}