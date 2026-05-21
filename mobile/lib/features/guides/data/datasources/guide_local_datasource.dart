import 'package:hive/hive.dart';

import '../models/category_model.dart';
import '../models/injury_model.dart';
import '../models/guide_model.dart';

class GuideLocalDataSource {

  // ================= CATEGORIES =================

  Future<List<CategoryModel>> getCategories() async {
    final box = Hive.box('categories');

    return box.values
        .map(
          (e) => CategoryModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ================= INJURIES =================

  Future<List<InjuryModel>> getInjuries() async {
    final box = Hive.box('injuries');

    return box.values
        .map(
          (e) => InjuryModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ================= GUIDES =================

  Future<List<GuideModel>> getGuides() async {
    final box = Hive.box('guides');

    return box.values
        .map(
          (e) => GuideModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}