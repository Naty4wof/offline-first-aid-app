import 'package:offline_first_aid_app/features/guides/data/models/injury_model.dart';

import '../../data/models/category_model.dart';
import '../../data/models/guide_model.dart';

abstract class GuideRepository {
  Future<List<GuideModel>> getGuides();
  Future<List<CategoryModel>> getCategories();
  Future<List<InjuryModel>> getInjuries();
  Future<List<GuideModel>> getGuidesByInjury(String injuryId);
  Future<List<InjuryModel>> getInjuriesByCategory(String categoryId);
}
