import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_aid_app/features/guides/data/repositories/guide_repository_impl.dart';
import 'package:offline_first_aid_app/features/guides/data/datasources/guide_local_datasource.dart';
import 'package:offline_first_aid_app/features/guides/data/models/injury_model.dart';
import 'package:offline_first_aid_app/features/guides/data/models/guide_model.dart';
import 'package:offline_first_aid_app/features/guides/data/models/category_model.dart';

class MockLocalDataSource implements GuideLocalDataSource {
  @override
  Future<List<CategoryModel>> getCategories() async {
    return [CategoryModel(id: 'c1', name: 'Test Cat', description: 'desc')];
  }

  @override
  Future<List<InjuryModel>> getInjuries() async {
    return [
      InjuryModel(
        id: 'i1',
        title: 'Test Injury',
        categoryId: 'c1',
        severity: 'minor',
        keywords: [],
      ),
    ];
  }

  @override
  Future<List<GuideModel>> getGuides() async {
    return [
      GuideModel(
        id: 'g1',
        injuryId: 'i1',
        title: 'Test Guide',
        description: 'desc',
        steps: ['Step 1'],
        symptoms: [],
        warnings: [],
        whenToSeekHelp: [],
        explanation: '',
        dos: [],
        donts: [],
      ),
    ];
  }
}

void main() {
  late GuideRepositoryImpl repository;
  late MockLocalDataSource dataSource;

  setUp(() {
    dataSource = MockLocalDataSource();
    repository = GuideRepositoryImpl(dataSource);
  });

  group('GuideRepositoryImpl Tests', () {
    test('getInjuriesByCategory should filter correctly', () async {
      final injuries = await repository.getInjuriesByCategory('c1');
      expect(injuries.length, 1);
      expect(injuries.first.id, 'i1');
    });

    test('getGuidesByInjury should filter correctly', () async {
      final guides = await repository.getGuidesByInjury('i1');
      expect(guides.length, 1);
      expect(guides.first.id, 'g1');
    });

    test('getCategories should return all categories', () async {
      final cats = await repository.getCategories();
      expect(cats.length, 1);
    });
  });
}
