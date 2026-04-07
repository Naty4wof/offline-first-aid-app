import 'dart:async';

import '../repositories/guide_repository.dart';
import '../../data/models/injury_model.dart';

class ChatResult {
  final InjuryModel? injury;
  final List<String> steps;
  final List<InjuryModel> suggestions;
  final double confidence;

  ChatResult({
    this.injury,
    required this.steps,
    this.suggestions = const [],
    this.confidence = 0,
  });
}

abstract class ChatService {
  Future<ChatResult> match(String input);
}

class ChatServiceImpl implements ChatService {
  final GuideRepository repository;

  ChatServiceImpl(this.repository);

  final Map<String, int> _priority = {
    'choking_adult': 10,
    'breathing_difficulty': 10,
    'bleeding_severe': 9,
    'poison_ingestion': 9,
    'seizure': 8,
    'snake_bite': 8,
    'burn_severe': 7,
    'fracture_basic': 6,
    'cut_deep': 6,
    'burn_minor': 3,
    'cut_minor': 3,
    'sprain': 2,
    'insect_sting': 2,
    'fainting': 4,
  };

  final Map<String, List<String>> _mapping = {
    'burn': [
      'burn',
      'hot',
      'fire',
      'boil',
      'scald',
      'ቃጠሎ',
      'ተቃጠለ',
      'እሳት',
      'ትኩሳት',
      'ሞቃት ውሃ',
    ],

    'bleeding': [
      'bleed',
      'bleeding',
      'blood',
      'ደም',
      'ደም መፍሰስ',
      'አይቆም',
      'ብዙ ደም',
    ],

    'breathing': [
      'breath',
      'air',
      'choke',
      'choking',
      'መተንፈስ',
      'አይተነፍስም',
      'አየር አጣ',
      'መታፈን',
    ],

    'fracture': [
      'fracture',
      'broken',
      'break',
      'bone',
      'ስብራት',
      'አጥንት ተሰበረ',
      'አይንቀሳቀስ',
    ],

    'wound': ['cut', 'wound', 'injury', 'ቁስል', 'ጥልቅ ቁስል', 'ንክሻ'],

    'poison': ['poison', 'chemical', 'toxic', 'መመረዝ', 'ኬሚካል', 'መድሃኒት'],

    'consciousness': [
      'faint',
      'unconscious',
      'dizzy',
      'ወደቀ',
      'ራስ ዞረ',
      'ማስታወቂያ መጥፋት',
    ],

    'seizure': ['seizure', 'convulsion', 'ንቀጠቀጠ', 'እንቅስቃሴ', 'አካል አይቆጠር'],

    'bite': ['bite', 'snake', 'insect', 'ንክሻ', 'እባብ', 'ነፍሳት'],
  };

  @override
  Future<ChatResult> match(String input) async {
    final q = input.toLowerCase();

    final words = q
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

    final injuries = await repository.getInjuries();
    final guides = await repository.getGuides();

    final Map<InjuryModel, double> scores = {};

    for (final injury in injuries) {
      double score = 0;

      final title = injury.title.toLowerCase();

      if (q.contains(title)) score += 8;

      for (final keyword in injury.keywords) {
        final k = keyword.toLowerCase();

        if (q.contains(k)) score += 5;

        for (final w in words) {
          if (k.contains(w)) score += 2;
        }
      }

      _mapping.forEach((concept, tokens) {
        for (final token in tokens) {
          if (q.contains(token)) {
            if (title.contains(concept) ||
                injury.keywords.any((k) => k.toLowerCase().contains(concept))) {
              score += 5;
            } else {
              score += 2;
            }
          }
        }
      });

      final relatedGuides = guides.where((g) => g.injuryId == injury.id);

      for (final g in relatedGuides) {
        for (final step in g.steps) {
          final s = step.toLowerCase();

          for (final w in words) {
            if (s.contains(w)) score += 0.5;
          }
        }
      }

      if (injury.severity == "severe") {
        if (q.contains("አይተነፍስም") ||
            q.contains("ብዙ ደም") ||
            q.contains("አይቆም") ||
            q.contains("unconscious")) {
          score += 5;
        }
      }

      score += (_priority[injury.id] ?? 1);

      scores[injury] = score;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty || sorted.first.value <= 0) {
      return ChatResult(
        injury: null,
        steps: [],
        suggestions: [],
        confidence: 0,
      );
    }

    final best = sorted.first.key;

    final suggestions = sorted.skip(1).take(2).map((e) => e.key).toList();

    final bestGuide = guides.firstWhere(
      (g) => g.injuryId == best.id,
      orElse: () => guides.first,
    );

    final maxScore = sorted.first.value;
    final double confidence = ((maxScore / 20).clamp(0.0, 1.0)).toDouble();

    return ChatResult(
      injury: best,
      steps: bestGuide.steps,
      suggestions: suggestions,
      confidence: confidence,
    );
  }
}
