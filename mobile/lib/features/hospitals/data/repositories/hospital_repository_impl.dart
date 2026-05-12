import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/hospital_model.dart';

abstract class HospitalRepository {
  Future<List<HospitalModel>> getHospitals();
  Future<void> updateHospitalsFromRemote();
}

class HospitalRepositoryImpl implements HospitalRepository {
  final String _hospitalBoxName = 'hospitals_box';

  @override
  Future<List<HospitalModel>> getHospitals() async {
    final box = await Hive.openBox(_hospitalBoxName);

    if (box.isNotEmpty) {
      return box.values.map((e) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(e);
        return HospitalModel.fromJson(data);
      }).toList();
    }

    // Load from assets if box is empty
    final jsonString = await rootBundle.loadString(
      'assets/data/hospitals.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    final List hospitalsList = data['hospitals'];

    final hospitals = hospitalsList
        .map((e) => HospitalModel.fromJson(e))
        .toList();

    // Save to local box for future use
    for (var hospital in hospitals) {
      await box.put(hospital.id, hospital.toJson());
    }

    return hospitals;
  }

  @override
  Future<void> updateHospitalsFromRemote() async {
    // In a real app, you would fetch from an API
    // Here we simulate it
    try {
      // Simulation of a remote fetch
      // final response = await http.get(Uri.parse('https://api.example.com/hospitals'));
      // if (response.statusCode == 200) { ... }

      // For this task, we will just "update" by adding a mock hospital or updating existing
      final box = await Hive.openBox(_hospitalBoxName);

      // Adding a new simulated hospital from "admin"
      final newHospital = HospitalModel(
        id: 'hosp_new_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Admin Updated Hospital',
        latitude: 9.0300,
        longitude: 38.7400,
        address: 'Updated Addis Ababa',
        phone: '911',
      );

      await box.put(newHospital.id, newHospital.toJson());
    } catch (e) {
      throw Exception('Failed to update hospitals: $e');
    }
  }
}
