import 'package:hive/hive.dart';
import 'user_model.dart';

class UserLocalService {
  final Box box = Hive.box('users');

  Future<void> saveUser(LocalUser user) async {
    await box.put(user.id, user.toMap());
  }

  List<LocalUser> getAllUsers() {
    return box.values
        .map((e) => LocalUser.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}