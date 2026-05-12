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
      'ተከሰተ',
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

  final List<String> _bodyParts = [
    'head',
    'face',
    'eye',
    'arm',
    'leg',
    'hand',
    'foot',
    'chest',
    'stomach',
    'back',
    'neck',
    'ራስ',
    'ፊት',
    'ዓይን',
    'እጅ',
    'እግር',
    'ደረት',
    'ሆድ',
    'ጀርባ',
    'አንገት',
  ];

  final List<String> _severeTokens = [
    'severe',
    'bleeding heavily',
    'not breathing',
    'unconscious',
    'passed out',
    'አይተነፍስም',
    'ብዙ ደም',
    'አይቆም',
    'ማስታወቂያ ጠፍቷል',
    'አይነቃም',
  ];

  String _normalize(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[\p{P}\p{S}]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  @override
  Future<ChatResult> match(String input) async {
    final q = _normalize(input);

    final words = q
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

    final injuries = await repository.getInjuries();
    final guides = await repository.getGuides();

    final Map<InjuryModel, double> scores = {};

    for (final injury in injuries) {
      double score = 0;
      int titleHits = 0;
      int keywordHits = 0;
      int conceptHits = 0;
      int bodyHits = 0;

      final title = injury.title.toLowerCase();

      if (q.contains(title)) {
        score += 8;
        titleHits += 1;
      }

      for (final keyword in injury.keywords) {
        final k = keyword.toLowerCase();

        if (q.contains(k)) {
          score += 6;
          keywordHits += 1;
        }

        for (final w in words) {
          if (k.contains(w)) {
            score += 2;
            keywordHits += 1;
          }
        }
      }

      _mapping.forEach((concept, tokens) {
        for (final token in tokens) {
          if (q.contains(token)) {
            if (title.contains(concept) ||
                injury.keywords.any((k) => k.toLowerCase().contains(concept))) {
              score += 5;
              conceptHits += 1;
            } else {
              score += 2;
              conceptHits += 1;
            }
          }
        }
      });

      for (final part in _bodyParts) {
        if (q.contains(part)) {
          score += 0.5;
          bodyHits += 1;
        }
      }

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
        for (final token in _severeTokens) {
          if (q.contains(token)) {
            score += 5;
            break;
          }
        }
      }

      if (titleHits + keywordHits + conceptHits == 0) {
        score = 0;
      } else if (bodyHits > 0) {
        score += bodyHits * 0.3;
      }

      if (score > 0) {
        score += (_priority[injury.id] ?? 1);
      }

      scores[injury] = score;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return ChatResult(
        injury: null,
        steps: [],
        suggestions: [],
        confidence: 0,
      );
    }

    final best = sorted.first.key;
    final suggestions = sorted.take(3).map((e) => e.key).toList();

    final bestGuide = guides.firstWhere(
      (g) => g.injuryId == best.id,
      orElse: () => guides.first,
    );

    final maxScore = sorted.first.value;
    final double confidence = ((maxScore / 20).clamp(0.0, 1.0)).toDouble();

    if (maxScore <= 0 || confidence < 0.35) {
      return ChatResult(
        injury: null,
        steps: [],
        suggestions: suggestions,
        confidence: confidence,
      );
    }

    return ChatResult(
      injury: best,
      steps: bestGuide.steps,
      suggestions: suggestions.where((i) => i.id != best.id).take(2).toList(),
      confidence: confidence,
    );
  }
}
