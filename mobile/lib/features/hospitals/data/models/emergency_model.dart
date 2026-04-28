class EmergencyModel {
  final String name;
  final String number;
  final String category;

  EmergencyModel({
    required this.name,
    required this.number,
    required this.category,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      name: json['name'],
      number: json['number'],
      category: json['category'],
    );
  }
}
