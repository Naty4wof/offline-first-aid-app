import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_aid_app/features/hospitals/data/repositories/hospital_repository_impl.dart';
import 'package:offline_first_aid_app/features/hospitals/data/models/hospital_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  group('HospitalRepositoryImpl Tests', () {
    late HospitalRepositoryImpl repository;

    setUp(() async {
      // Initialize Hive for testing in a temporary directory
      final tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      repository = HospitalRepositoryImpl();
    });

    tearDown(() async {
      await Hive.close();
    });

    test(
      'updateHospitalsFromRemote should add a hospital to the box',
      () async {
        final box = await Hive.openBox('hospitals_box');
        final initialCount = box.length;

        await repository.updateHospitalsFromRemote();

        expect(box.length, equals(initialCount + 1));
        final lastHospital = HospitalModel.fromJson(
          Map<String, dynamic>.from(box.values.last),
        );
        expect(lastHospital.name, equals('Admin Updated Hospital'));
      },
    );
  });
}
