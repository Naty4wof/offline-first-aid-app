import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> syncUserProfile(Map<String, dynamic> profile) async {
    await _db.collection('users').doc('device_user').set(profile);
  }
}