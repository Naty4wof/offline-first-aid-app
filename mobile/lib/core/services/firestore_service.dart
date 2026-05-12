import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser({
    required String id,
    required String name,
    required String medicalInfo,
  }) async {
    await _db.collection('users').doc(id).set({
      'name': name,
      'medicalInfo': medicalInfo,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}