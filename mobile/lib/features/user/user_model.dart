class LocalUser {
  final String id;
  final String name;
  final String age;
  final String bloodType;
  final String medical;
  final bool isSynced;

  LocalUser({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodType,
    required this.medical,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bloodType': bloodType,
      'medical': medical,
      'isSynced': isSynced,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      bloodType: map['bloodType'],
      medical: map['medical'],
      isSynced: map['isSynced'] ?? false,
    );
  }
}