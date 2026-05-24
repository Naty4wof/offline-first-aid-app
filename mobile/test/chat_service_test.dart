import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_aid_app/features/guides/domain/services/chat_service.dart';
import 'package:offline_first_aid_app/features/guides/domain/repositories/guide_repository.dart';
import 'package:offline_first_aid_app/features/guides/data/models/injury_model.dart';
import 'package:offline_first_aid_app/features/guides/data/models/guide_model.dart';
import 'package:offline_first_aid_app/features/guides/data/models/category_model.dart';

class MockGuideRepository implements GuideRepository {
  @override
  Future<List<InjuryModel>> getInjuries() async {
    return [
      InjuryModel(
        id: 'bleeding_severe',
        title: 'Severe Bleeding',
        categoryId: 'trauma',
        severity: 'severe',
        keywords: ['blood', 'bleed', 'ደም', 'ተከሰተ'],
      ),
      InjuryModel(
        id: 'burn_minor',
        title: 'Minor Burn',
        categoryId: 'burns',
        severity: 'minor',
        keywords: ['burn', 'hot', 'ቃጠሎ', 'ተቃጠለ'],
      ),
    ];
  }

  @override
  Future<List<GuideModel>> getGuides() async {
    return [
      GuideModel(
        id: 'g1',
        injuryId: 'bleeding_severe',
        title: 'How to stop bleeding',
        description: 'Guide for severe bleeding',
        steps: ['Apply pressure', 'Elevate'],
        symptoms: [],
        warnings: [],
        whenToSeekHelp: [],
        explanation: '',
        dos: [],
        donts: [],
      ),
      GuideModel(
        id: 'g2',
        injuryId: 'burn_minor',
        title: 'Treating minor burns',
        description: 'Guide for minor burns',
        steps: ['Cool water', 'Cover'],
        symptoms: [],
        warnings: [],
        whenToSeekHelp: [],
        explanation: '',
        dos: [],
        donts: [],
      ),
    ];
  }

  @override
  Future<List<CategoryModel>> getCategories() async => [];
  @override
  Future<List<GuideModel>> getGuidesByInjury(String id) async => [];
  @override
  Future<List<InjuryModel>> getInjuriesByCategory(String id) async => [];
}

void main() {
  late ChatServiceImpl chatService;
  late MockGuideRepository repository;

  setUp(() {
    repository = MockGuideRepository();
    chatService = ChatServiceImpl(repository);
  });

  group('ChatServiceImpl Tests', () {
    test('Should match English keyword "bleed"', () async {
      final result = await chatService.match('I am bleeding');
      expect(result.injury?.id, equals('bleeding_severe'));
      expect(result.confidence, greaterThan(0.35));
    });

    test('Should match Amharic keyword "ደም"', () async {
      final result = await chatService.match('ደም እየፈሰሰ ነው');
      expect(result.injury?.id, equals('bleeding_severe'));
    });

    test('Should match Amharic keyword "ተቃጠለ"', () async {
      final result = await chatService.match('እጄ ተቃጠለ');
      expect(result.injury?.id, equals('burn_minor'));
    });

    test('Should return low confidence for unrelated input', () async {
      final result = await chatService.match('Hello how are you');
      expect(result.injury, isNull);
      expect(result.confidence, lessThan(0.35));
    });

    test('Should handle severe tokens correctly', () async {
      final result = await chatService.match('heavy bleeding');
      expect(result.injury?.id, equals('bleeding_severe'));
      expect(result.confidence, greaterThan(0.5));
    });
  });
}
