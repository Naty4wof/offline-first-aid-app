import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_aid_app/features/user/user_service.dart';
import 'package:offline_first_aid_app/features/hospitals/data/repositories/hospital_repository_impl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

// Mocking UserService to avoid Firebase initialization error
class MockUserService extends UserService {
  @override
  Future<void> syncUserProfile(Map<String, dynamic> profile) async {}
}

void main() {
  group('Cross-Tier Integration Tests', () {
    late HospitalRepositoryImpl repo;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      repo = HospitalRepositoryImpl();
    });

    tearDown(() async {
      await Hive.close();
    });

    test('HospitalRepository fetch simulation (Admin to Mobile)', () async {
      final box = await Hive.openBox('hospitals_box');

      // Simulate Admin updating a hospital remotely
      // In our mock repo, updateHospitalsFromRemote is self-contained
      await repo.updateHospitalsFromRemote();

      expect(
        box.values.any((h) => h['name'] == 'Admin Updated Hospital'),
        isTrue,
      );
    });
  });
}
