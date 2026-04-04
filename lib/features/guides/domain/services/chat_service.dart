import 'dart:async';

import '../repositories/guide_repository.dart';
import '../../data/models/injury_model.dart';

class ChatResult {
  final InjuryModel? injury;
  final List<String> steps;
  final List<InjuryModel> suggestions;

  ChatResult({this.injury, required this.steps, this.suggestions = const []});
}

abstract class ChatService {
  Future<ChatResult> match(String input);
}

class ChatServiceImpl implements ChatService {
  final GuideRepository repository;

  // simple keyword map (can be extended or loaded externally)
  final Map<String, List<String>> _mapping = {
    // English + Amharic tokens
    'burn': ['burn', 'hot', 'fire', 'boil', 'scald', 'ቃጠሎ', 'እሳት', 'ትኩሳት'],
    'cut': [
      'cut',
      'bleed',
      'bleeding',
      'knife',
      'laceration',
      'መቆላወጥ',
      'ደም',
      'መደምሰስ',
      'ሽንስ',
    ],
    'fracture': ['fracture', 'broken', 'break', 'sprain', 'ስብራት', 'መሰብሰብ'],
    'choking': ['choke', 'choking', 'swallow', 'airway', 'መታፈን', 'ዝግ'],
    'allergy': [
      'allergy',
      'allergic',
      'reaction',
      'anaphylaxis',
      'አለርጂ',
      'አለርጂክ',
    ],
  };

  ChatServiceImpl(this.repository);

  @override
  Future<ChatResult> match(String input) async {
    final q = input.toLowerCase();

    final injuries = await repository.getInjuries();
    final guides = await repository.getGuides();

    // score injuries
    final Map<InjuryModel, int> scores = {};

    // split on whitespace to support Amharic and other scripts
    final words = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    for (final injury in injuries) {
      var score = 0;
      final title = injury.title.toLowerCase();
      // direct match against title or full query contains title
      if (title.isNotEmpty && q.contains(title)) score += 6;

      // match against title by tokens
      for (final w in words) {
        if (title.contains(w)) score += 2;
      }

      // match against injury keywords (also check full query contains keyword)
      for (final k in injury.keywords) {
        final lk = k.toLowerCase();
        if (lk.isNotEmpty && q.contains(lk)) score += 4;
        for (final w in words) if (lk.contains(w)) score += 2;
      }

      // mapping-based boosts
      _mapping.forEach((key, list) {
        for (final token in list) {
          if (q.contains(token)) {
            if (title.contains(key) ||
                injury.keywords.any((kk) => kk.toLowerCase().contains(key))) {
              score += 4;
            } else {
              // small boost even if mapping doesn't directly match
              if (title.contains(token) ||
                  injury.keywords.any((kk) => kk.toLowerCase().contains(token)))
                score += 2;
            }
          }
        }
      });

      // similarity via guides steps
      final relatedGuides = guides.where((g) => g.injuryId == injury.id);
      for (final g in relatedGuides) {
        for (final s in g.steps) {
          final ls = s.toLowerCase();
          for (final w in words) if (ls.contains(w)) score += 1;
        }
      }

      scores[injury] = score;
    }

    // sort injuries by score
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty || sorted.first.value <= 0) {
      // nothing matched
      return ChatResult(injury: null, steps: [], suggestions: []);
    }

    final best = sorted.first.key;
    final topSuggestions = sorted
        .where((e) => e.value > 0)
        .take(2)
        .map((e) => e.key)
        .toList();

    // get guide steps for best injury (first guide)
    final bestGuides = guides.where((g) => g.injuryId == best.id).toList();
    final steps = bestGuides.isNotEmpty ? bestGuides.first.steps : <String>[];

    return ChatResult(injury: best, steps: steps, suggestions: topSuggestions);
  }
}
