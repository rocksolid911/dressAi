import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clothing_item_model.dart';
import '../models/outfit_model.dart';
import '../models/weather_model.dart';
import '../models/recommendation_log_model.dart';

class OutfitRecommendation {
  final List<ClothingItemModel> items;
  final String explanation;
  final double score;
  final List<String> stylingTips;

  OutfitRecommendation({
    required this.items,
    required this.explanation,
    required this.score,
    required this.stylingTips,
  });
}

class AiStylistService {
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  // Generate outfit recommendations
  Future<List<OutfitRecommendation>> generateRecommendations({
    required List<ClothingItemModel> wardrobe,
    required RecommendationContext context,
    int maxRecommendations = 5,
  }) async {
    try {
      // Filter wardrobe based on context
      final filteredWardrobe = _filterWardrobeByContext(wardrobe, context);

      if (filteredWardrobe.isEmpty) {
        return [];
      }

      // Generate outfit combinations
      final combinations = _generateOutfitCombinations(filteredWardrobe);

      // Score and rank combinations
      final scoredCombinations = _scoreOutfits(combinations, context);

      // Get AI explanations for top combinations
      final recommendations = await _generateExplanations(
        scoredCombinations.take(maxRecommendations).toList(),
        context,
      );

      return recommendations;
    } catch (e) {
      throw Exception('Failed to generate recommendations: ${e.toString()}');
    }
  }

  // Filter wardrobe by context
  List<ClothingItemModel> _filterWardrobeByContext(
    List<ClothingItemModel> wardrobe,
    RecommendationContext context,
  ) {
    return wardrobe.where((item) {
      bool matches = true;

      // Filter by weather/season
      if (context.weather != null && context.temperature != null) {
        final suitableSeason = _getSuitableSeasonForTemp(context.temperature!);
        if (item.season != 'All Season' && item.season != suitableSeason) {
          matches = false;
        }
      }

      // Filter by occasion
      if (context.occasion != null && item.occasionTags.isNotEmpty) {
        if (!item.occasionTags.contains(context.occasion)) {
          matches = false;
        }
      }

      return matches;
    }).toList();
  }

  String _getSuitableSeasonForTemp(double temp) {
    if (temp < 15) return 'Winter';
    if (temp < 25) return 'Spring';
    return 'Summer';
  }

  // Generate outfit combinations
  List<List<ClothingItemModel>> _generateOutfitCombinations(
    List<ClothingItemModel> wardrobe,
  ) {
    List<List<ClothingItemModel>> combinations = [];

    // Separate by category
    final tops = wardrobe.where((i) => i.category == 'Tops').toList();
    final bottoms = wardrobe.where((i) => i.category == 'Bottoms').toList();
    final dresses = wardrobe.where((i) => i.category == 'Dresses').toList();
    final shoes = wardrobe.where((i) => i.category == 'Shoes').toList();
    final outerwear = wardrobe.where((i) => i.category == 'Outerwear').toList();
    final accessories = wardrobe.where((i) => i.category == 'Accessories').toList();

    // Generate top + bottom + shoes combinations
    for (var top in tops) {
      for (var bottom in bottoms) {
        if (shoes.isNotEmpty) {
          for (var shoe in shoes.take(2)) {
            List<ClothingItemModel> outfit = [top, bottom, shoe];

            // Optionally add outerwear
            if (outerwear.isNotEmpty) {
              outfit.add(outerwear.first);
            }

            // Optionally add accessory
            if (accessories.isNotEmpty) {
              outfit.add(accessories.first);
            }

            combinations.add(outfit);

            if (combinations.length >= 20) break;
          }
        }
        if (combinations.length >= 20) break;
      }
      if (combinations.length >= 20) break;
    }

    // Generate dress + shoes combinations
    for (var dress in dresses.take(5)) {
      if (shoes.isNotEmpty) {
        for (var shoe in shoes.take(2)) {
          List<ClothingItemModel> outfit = [dress, shoe];

          if (accessories.isNotEmpty) {
            outfit.add(accessories.first);
          }

          combinations.add(outfit);

          if (combinations.length >= 20) break;
        }
      }
      if (combinations.length >= 20) break;
    }

    return combinations;
  }

  // Score outfits based on context
  List<List<ClothingItemModel>> _scoreOutfits(
    List<List<ClothingItemModel>> combinations,
    RecommendationContext context,
  ) {
    final scored = combinations.map((outfit) {
      double score = 0.0;

      // Color harmony
      score += _calculateColorHarmony(outfit) * 0.3;

      // Occasion appropriateness
      if (context.occasion != null) {
        score += _calculateOccasionScore(outfit, context.occasion!) * 0.3;
      }

      // Variety (not worn recently)
      score += _calculateVarietyScore(outfit) * 0.2;

      // Style consistency
      score += _calculateStyleConsistency(outfit) * 0.2;

      return {'outfit': outfit, 'score': score};
    }).toList();

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return scored.map((s) => s['outfit'] as List<ClothingItemModel>).toList();
  }

  double _calculateColorHarmony(List<ClothingItemModel> outfit) {
    // Simplified color harmony calculation
    final colors = outfit.map((i) => i.color).toSet();

    // Prefer 2-3 colors
    if (colors.length == 2 || colors.length == 3) {
      return 1.0;
    } else if (colors.length == 1) {
      return 0.8;
    } else {
      return 0.5;
    }
  }

  double _calculateOccasionScore(List<ClothingItemModel> outfit, String occasion) {
    int matches = 0;
    for (var item in outfit) {
      if (item.occasionTags.contains(occasion)) {
        matches++;
      }
    }
    return matches / outfit.length;
  }

  double _calculateVarietyScore(List<ClothingItemModel> outfit) {
    // Items not worn recently score higher
    int recentlyWorn = 0;
    final now = DateTime.now();

    for (var item in outfit) {
      if (item.lastWornAt != null) {
        final daysSince = now.difference(item.lastWornAt!).inDays;
        if (daysSince < 7) {
          recentlyWorn++;
        }
      }
    }

    return 1.0 - (recentlyWorn / outfit.length);
  }

  double _calculateStyleConsistency(List<ClothingItemModel> outfit) {
    // Check if all items have compatible tags
    final allTags = outfit.expand((i) => i.tags).toSet();

    // Conflicting styles
    if (allTags.contains('formal') && allTags.contains('sporty')) {
      return 0.3;
    }

    return 0.8;
  }

  // Generate AI explanations
  Future<List<OutfitRecommendation>> _generateExplanations(
    List<List<ClothingItemModel>> outfits,
    RecommendationContext context,
  ) async {
    List<OutfitRecommendation> recommendations = [];

    for (var outfit in outfits) {
      try {
        final explanation = await _getAiExplanation(outfit, context);
        final tips = _generateStylingTips(outfit, context);

        recommendations.add(OutfitRecommendation(
          items: outfit,
          explanation: explanation,
          score: 0.85,
          stylingTips: tips,
        ));
      } catch (e) {
        // Use fallback explanation
        recommendations.add(OutfitRecommendation(
          items: outfit,
          explanation: _getFallbackExplanation(outfit, context),
          score: 0.75,
          stylingTips: _generateStylingTips(outfit, context),
        ));
      }
    }

    return recommendations;
  }

  // Get AI-generated explanation
  Future<String> _getAiExplanation(
    List<ClothingItemModel> outfit,
    RecommendationContext context,
  ) async {
    try {
      final outfitDescription = outfit.map((item) {
        return '${item.color} ${item.subcategory}';
      }).join(', ');

      final prompt = '''
Create a short, friendly explanation (2-3 sentences) for this outfit recommendation:
Items: $outfitDescription
Occasion: ${context.occasion ?? 'general'}
Weather: ${context.weather ?? 'any'} (${context.temperature ?? 'comfortable'}°C)
Mood: ${context.mood ?? 'confident'}

Explain why this outfit works well for the context.
''';

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a friendly fashion stylist.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].trim();
      } else {
        return _getFallbackExplanation(outfit, context);
      }
    } catch (e) {
      return _getFallbackExplanation(outfit, context);
    }
  }

  // Fallback explanation
  String _getFallbackExplanation(
    List<ClothingItemModel> outfit,
    RecommendationContext context,
  ) {
    final items = outfit.map((i) => i.subcategory.toLowerCase()).join(', ');

    if (context.occasion != null) {
      return 'This combination of $items is perfect for ${context.occasion!.toLowerCase()}. '
          'The colors work well together and the style is appropriate for the occasion.';
    } else if (context.weather != null) {
      return 'Great choice for ${context.weather!.toLowerCase()} weather! '
          'This outfit with $items will keep you comfortable throughout the day.';
    } else {
      return 'This stylish outfit featuring $items creates a balanced, put-together look '
          'that\'s versatile for various occasions.';
    }
  }

  // Generate styling tips
  List<String> _generateStylingTips(
    List<ClothingItemModel> outfit,
    RecommendationContext context,
  ) {
    List<String> tips = [];

    // Weather-based tips
    if (context.temperature != null) {
      if (context.temperature! < 15) {
        tips.add('Layer up for warmth - consider adding a scarf or jacket');
      } else if (context.temperature! > 28) {
        tips.add('Stay cool with light, breathable fabrics');
      }
    }

    if (context.weather == 'Rain') {
      tips.add('Don\'t forget an umbrella or raincoat!');
    }

    // Occasion-based tips
    if (context.occasion == 'Office') {
      tips.add('Keep accessories minimal and professional');
    } else if (context.occasion == 'Party') {
      tips.add('Add a statement accessory to elevate the look');
    } else if (context.occasion == 'Date') {
      tips.add('Confidence is key - wear what makes you feel great!');
    }

    // Color-based tips
    final colors = outfit.map((i) => i.color).toSet();
    if (colors.length == 1) {
      tips.add('Monochrome look - add texture for visual interest');
    }

    return tips;
  }

  // Parse natural language input
  Future<RecommendationContext> parseNaturalLanguageInput(String input) async {
    try {
      final prompt = '''
Extract structured information from this fashion request:
"$input"

Identify:
1. Occasion (Casual, Office, Formal, Party, Wedding, Date, Sports, Beach, Festival, Interview)
2. Mood (Confident, Cozy, Bold, Minimal, Playful, Elegant, Relaxed, Professional, Romantic, Edgy)
3. Weather conditions if mentioned
4. Time of day if mentioned
5. Any specific preferences

Respond in JSON format with keys: occasion, mood, weather, preferences
''';

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a fashion context analyzer.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
        },
      );

      if (response.statusCode == 200) {
        // Parse JSON response
        final content = response.data['choices'][0]['message']['content'];
        return _parseContextFromResponse(content, input);
      } else {
        return _fallbackContextParsing(input);
      }
    } catch (e) {
      return _fallbackContextParsing(input);
    }
  }

  RecommendationContext _parseContextFromResponse(String content, String original) {
    // Simple parsing - in production, use proper JSON parsing
    return RecommendationContext(
      occasion: _extractOccasion(original),
      mood: _extractMood(original),
      userPrompt: original,
    );
  }

  RecommendationContext _fallbackContextParsing(String input) {
    return RecommendationContext(
      occasion: _extractOccasion(input),
      mood: _extractMood(input),
      userPrompt: input,
    );
  }

  String? _extractOccasion(String input) {
    final lowered = input.toLowerCase();
    if (lowered.contains('office') || lowered.contains('work')) return 'Office';
    if (lowered.contains('party')) return 'Party';
    if (lowered.contains('wedding')) return 'Wedding';
    if (lowered.contains('date')) return 'Date';
    if (lowered.contains('casual')) return 'Casual';
    if (lowered.contains('formal')) return 'Formal';
    if (lowered.contains('interview')) return 'Interview';
    if (lowered.contains('beach')) return 'Beach';
    if (lowered.contains('sport') || lowered.contains('gym')) return 'Sports';
    return null;
  }

  String? _extractMood(String input) {
    final lowered = input.toLowerCase();
    if (lowered.contains('confident')) return 'Confident';
    if (lowered.contains('cozy') || lowered.contains('comfortable')) return 'Cozy';
    if (lowered.contains('bold')) return 'Bold';
    if (lowered.contains('minimal')) return 'Minimal';
    if (lowered.contains('playful') || lowered.contains('fun')) return 'Playful';
    if (lowered.contains('elegant')) return 'Elegant';
    if (lowered.contains('relaxed') || lowered.contains('chill')) return 'Relaxed';
    if (lowered.contains('professional')) return 'Professional';
    if (lowered.contains('romantic')) return 'Romantic';
    if (lowered.contains('edgy')) return 'Edgy';
    return null;
  }
}
