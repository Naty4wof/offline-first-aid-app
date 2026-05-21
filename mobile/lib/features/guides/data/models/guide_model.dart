class GuideModel {
  final String id;
  final String injuryId;
  final String title;

  final String description;
  final List<String> symptoms;
  final List<String> steps;
  final List<String> warnings;
  final List<String> whenToSeekHelp;
  final String explanation;
  final List<String> dos;
  final List<String> donts;

  final String? imagePath;
  final String? audioPath;

  GuideModel({
    required this.id,
    required this.injuryId,
    required this.title,
    required this.description,
    required this.symptoms,
    required this.steps,
    required this.warnings,
    required this.whenToSeekHelp,
    required this.explanation,
    required this.dos,
    required this.donts,
    this.imagePath,
    this.audioPath,
  });

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    return GuideModel(
      id: json['id']?.toString() ?? '',
      injuryId: json['injuryId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',

      description: json['description']?.toString() ?? '',

      symptoms: List<String>.from(json['symptoms'] ?? []),

      steps: List<String>.from(json['steps'] ?? []),

      warnings: List<String>.from(json['warnings'] ?? []),

      whenToSeekHelp: List<String>.from(json['whenToSeekHelp'] ?? []),

      explanation: json['explanation']?.toString() ?? '',

      dos: List<String>.from(json['dos'] ?? []),

      donts: List<String>.from(json['donts'] ?? []),

      imagePath: json['imagePath']?.toString(),

      audioPath: json['audioPath']?.toString(),
    );
  }
}
