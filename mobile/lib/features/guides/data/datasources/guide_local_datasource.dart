import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../models/injury_model.dart';
import '../models/guide_model.dart';

class GuideLocalDataSource {
  Future<Map<String, dynamic>> loadJson() async {
    final jsonString =
        await rootBundle.loadString('assets/data/guides_am.json');
    return json.decode(jsonString);
  }

  Future<List<CategoryModel>> getCategories() async {
    final data = await loadJson();
    return (data['categories'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }

  Future<List<InjuryModel>> getInjuries() async {
    final data = await loadJson();
    return (data['injuries'] as List)
        .map((e) => InjuryModel.fromJson(e))
        .toList();
  }

  Future<List<GuideModel>> getGuides() async {
    final data = await loadJson();
    return (data['guides'] as List)
        .map((e) => GuideModel.fromJson(e))
        .toList();
  }
}