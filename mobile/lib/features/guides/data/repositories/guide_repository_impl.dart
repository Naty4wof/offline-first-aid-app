import 'package:offline_first_aid_app/features/guides/data/models/injury_model.dart';

import '../../domain/repositories/guide_repository.dart';
import '../datasources/guide_local_datasource.dart';
import '../models/category_model.dart';
import '../models/guide_model.dart';

class GuideRepositoryImpl implements GuideRepository {
  final GuideLocalDataSource localDataSource;

  GuideRepositoryImpl(this.localDataSource);

  @override
  Future<List<GuideModel>> getGuides() async {
    return await localDataSource.getGuides();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return await localDataSource.getCategories();
  }

  @override
  Future<List<InjuryModel>> getInjuries() async {
    return await localDataSource.getInjuries();
  }

  @override
  Future<List<GuideModel>> getGuidesByInjury(String injuryId) async {
    final guides = await localDataSource.getGuides();

    return guides.where((g) => g.injuryId == injuryId).toList();
  }

  @override
  Future<List<InjuryModel>> getInjuriesByCategory(String categoryId) async {
    final injuries = await localDataSource.getInjuries();

    return injuries.where((i) => i.categoryId == categoryId).toList();
  }
}
