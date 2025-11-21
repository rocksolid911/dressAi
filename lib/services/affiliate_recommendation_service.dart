import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clothing_item_model.dart';
import '../models/shopping_item_model.dart';
import '../core/constants/app_constants.dart';

class AffiliateRecommendationService {
  final Dio _dio = Dio();
  final String _affiliateBaseUrl = dotenv.env['AFFILIATE_BASE_URL'] ?? '';

  // Get shopping recommendations based on wardrobe item
  Future<List<ShoppingItemModel>> getRecommendationsForItem(
    ClothingItemModel item,
  ) async {
    try {
      // Analyze what pairs well with this item
      final recommendations = _generateComplementaryRecommendations(item);

      return recommendations;
    } catch (e) {
      throw Exception('Failed to get recommendations: ${e.toString()}');
    }
  }

  // Get recommendations to fill wardrobe gaps
  Future<List<ShoppingItemModel>> getWardrobeGapRecommendations(
    List<ClothingItemModel> wardrobe,
  ) async {
    try {
      // Analyze wardrobe to find gaps
      final gaps = _analyzeWardrobeGaps(wardrobe);

      // Generate recommendations to fill gaps
      final recommendations = _generateGapFillerRecommendations(gaps);

      return recommendations;
    } catch (e) {
      throw Exception('Failed to analyze wardrobe: ${e.toString()}');
    }
  }

  // Get recommendations for specific occasion
  Future<List<ShoppingItemModel>> getOccasionRecommendations({
    required String occasion,
    required List<ClothingItemModel> existingWardrobe,
  }) async {
    try {
      // Determine what's missing for this occasion
      final needed = _determineOccasionNeeds(occasion, existingWardrobe);

      // Generate recommendations
      final recommendations = _generateOccasionRecommendations(occasion, needed);

      return recommendations;
    } catch (e) {
      throw Exception('Failed to get occasion recommendations: ${e.toString()}');
    }
  }

  // Generate complementary recommendations for an item
  List<ShoppingItemModel> _generateComplementaryRecommendations(
    ClothingItemModel item,
  ) {
    List<ShoppingItemModel> recommendations = [];

    // Rules for pairing items
    if (item.category == 'Tops') {
      // Recommend bottoms
      recommendations.addAll(_generateBottomRecommendations(item));

      // Recommend shoes
      recommendations.addAll(_generateShoeRecommendations(item));
    } else if (item.category == 'Bottoms') {
      // Recommend tops
      recommendations.addAll(_generateTopRecommendations(item));

      // Recommend shoes
      recommendations.addAll(_generateShoeRecommendations(item));
    } else if (item.category == 'Dresses') {
      // Recommend shoes and accessories
      recommendations.addAll(_generateShoeRecommendations(item));
      recommendations.addAll(_generateAccessoryRecommendations(item));
    }

    return recommendations.take(10).toList();
  }

  List<ShoppingItemModel> _generateBottomRecommendations(ClothingItemModel top) {
    List<ShoppingItemModel> recommendations = [];

    // Color pairing logic
    final complementaryColors = _getComplementaryColors(top.color);

    for (var color in complementaryColors.take(3)) {
      // Formal top → recommend formal bottoms
      if (top.occasionTags.contains('Formal') ||
          top.occasionTags.contains('Office')) {
        recommendations.add(_createMockShoppingItem(
          name: '$color Formal Trousers',
          category: 'Bottoms',
          color: color,
          price: 1999,
        ));
      } else {
        recommendations.add(_createMockShoppingItem(
          name: '$color Jeans',
          category: 'Bottoms',
          color: color,
          price: 1499,
        ));
      }
    }

    return recommendations;
  }

  List<ShoppingItemModel> _generateTopRecommendations(ClothingItemModel bottom) {
    List<ShoppingItemModel> recommendations = [];

    final complementaryColors = _getComplementaryColors(bottom.color);

    for (var color in complementaryColors.take(3)) {
      if (bottom.occasionTags.contains('Formal')) {
        recommendations.add(_createMockShoppingItem(
          name: '$color Formal Shirt',
          category: 'Tops',
          color: color,
          price: 1299,
        ));
      } else {
        recommendations.add(_createMockShoppingItem(
          name: '$color T-Shirt',
          category: 'Tops',
          color: color,
          price: 599,
        ));
      }
    }

    return recommendations;
  }

  List<ShoppingItemModel> _generateShoeRecommendations(ClothingItemModel item) {
    List<ShoppingItemModel> recommendations = [];

    if (item.occasionTags.contains('Formal') ||
        item.occasionTags.contains('Office')) {
      recommendations.add(_createMockShoppingItem(
        name: 'Black Formal Shoes',
        category: 'Shoes',
        color: 'Black',
        price: 2499,
      ));
      recommendations.add(_createMockShoppingItem(
        name: 'Brown Loafers',
        category: 'Shoes',
        color: 'Brown',
        price: 2299,
      ));
    } else if (item.occasionTags.contains('Sports')) {
      recommendations.add(_createMockShoppingItem(
        name: 'Running Sneakers',
        category: 'Shoes',
        color: 'White',
        price: 3499,
      ));
    } else {
      recommendations.add(_createMockShoppingItem(
        name: 'White Sneakers',
        category: 'Shoes',
        color: 'White',
        price: 1999,
      ));
    }

    return recommendations;
  }

  List<ShoppingItemModel> _generateAccessoryRecommendations(
      ClothingItemModel item) {
    List<ShoppingItemModel> recommendations = [];

    recommendations.add(_createMockShoppingItem(
      name: 'Statement Necklace',
      category: 'Accessories',
      color: 'Gold',
      price: 799,
    ));

    recommendations.add(_createMockShoppingItem(
      name: 'Elegant Watch',
      category: 'Accessories',
      color: 'Silver',
      price: 2999,
    ));

    return recommendations;
  }

  // Analyze wardrobe gaps
  Map<String, int> _analyzeWardrobeGaps(List<ClothingItemModel> wardrobe) {
    Map<String, int> categoryCounts = {};

    for (var category in AppConstants.clothingCategories) {
      categoryCounts[category] =
          wardrobe.where((item) => item.category == category).length;
    }

    // Identify gaps (categories with few items)
    Map<String, int> gaps = {};
    categoryCounts.forEach((category, count) {
      if (count < 3) {
        gaps[category] = 3 - count;
      }
    });

    return gaps;
  }

  // Generate recommendations to fill gaps
  List<ShoppingItemModel> _generateGapFillerRecommendations(
    Map<String, int> gaps,
  ) {
    List<ShoppingItemModel> recommendations = [];

    gaps.forEach((category, needed) {
      if (category == 'Tops') {
        recommendations.add(_createMockShoppingItem(
          name: 'Classic White T-Shirt',
          category: 'Tops',
          color: 'White',
          price: 599,
        ));
        recommendations.add(_createMockShoppingItem(
          name: 'Navy Blue Shirt',
          category: 'Tops',
          color: 'Navy',
          price: 1299,
        ));
      } else if (category == 'Bottoms') {
        recommendations.add(_createMockShoppingItem(
          name: 'Dark Blue Jeans',
          category: 'Bottoms',
          color: 'Blue',
          price: 1999,
        ));
      } else if (category == 'Shoes') {
        recommendations.add(_createMockShoppingItem(
          name: 'Versatile Sneakers',
          category: 'Shoes',
          color: 'White',
          price: 2499,
        ));
      }
    });

    return recommendations;
  }

  // Determine needs for specific occasion
  List<String> _determineOccasionNeeds(
    String occasion,
    List<ClothingItemModel> wardrobe,
  ) {
    // Check what user has for this occasion
    final occasionItems = wardrobe
        .where((item) => item.occasionTags.contains(occasion))
        .toList();

    List<String> needed = [];

    // Basic needs for each occasion
    if (occasion == 'Office' || occasion == 'Formal') {
      final hasFormalTop =
          occasionItems.any((i) => i.category == 'Tops' && i.occasionTags.contains(occasion));
      final hasFormalBottom =
          occasionItems.any((i) => i.category == 'Bottoms' && i.occasionTags.contains(occasion));
      final hasFormalShoes =
          occasionItems.any((i) => i.category == 'Shoes' && i.occasionTags.contains(occasion));

      if (!hasFormalTop) needed.add('Formal Top');
      if (!hasFormalBottom) needed.add('Formal Bottom');
      if (!hasFormalShoes) needed.add('Formal Shoes');
    } else if (occasion == 'Party') {
      final hasPartyOutfit = occasionItems.any(
          (i) => i.category == 'Dresses' || i.tags.contains('stylish'));

      if (!hasPartyOutfit) needed.add('Party Outfit');
    }

    return needed;
  }

  // Generate occasion-specific recommendations
  List<ShoppingItemModel> _generateOccasionRecommendations(
    String occasion,
    List<String> needed,
  ) {
    List<ShoppingItemModel> recommendations = [];

    for (var need in needed) {
      if (need == 'Formal Top') {
        recommendations.add(_createMockShoppingItem(
          name: 'White Formal Shirt',
          category: 'Tops',
          color: 'White',
          price: 1499,
        ));
      } else if (need == 'Formal Bottom') {
        recommendations.add(_createMockShoppingItem(
          name: 'Black Formal Trousers',
          category: 'Bottoms',
          color: 'Black',
          price: 1999,
        ));
      } else if (need == 'Formal Shoes') {
        recommendations.add(_createMockShoppingItem(
          name: 'Black Oxford Shoes',
          category: 'Shoes',
          color: 'Black',
          price: 2999,
        ));
      } else if (need == 'Party Outfit') {
        recommendations.add(_createMockShoppingItem(
          name: 'Elegant Party Dress',
          category: 'Dresses',
          color: 'Black',
          price: 3499,
        ));
      }
    }

    return recommendations;
  }

  // Get complementary colors
  List<String> _getComplementaryColors(String color) {
    final colorPairs = {
      'White': ['Black', 'Blue', 'Red', 'Navy'],
      'Black': ['White', 'Grey', 'Red', 'Blue'],
      'Blue': ['White', 'Beige', 'Grey', 'Brown'],
      'Red': ['Black', 'White', 'Navy', 'Grey'],
      'Green': ['Brown', 'Beige', 'White', 'Black'],
      'Yellow': ['Grey', 'Blue', 'Black', 'White'],
      'Navy': ['White', 'Beige', 'Grey', 'Brown'],
      'Grey': ['White', 'Black', 'Blue', 'Pink'],
      'Brown': ['Beige', 'White', 'Blue', 'Green'],
      'Beige': ['Brown', 'White', 'Navy', 'Black'],
    };

    return colorPairs[color] ?? ['White', 'Black', 'Blue', 'Grey'];
  }

  // Create mock shopping item (in production, fetch from real API)
  ShoppingItemModel _createMockShoppingItem({
    required String name,
    required String category,
    required String color,
    required double price,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    return ShoppingItemModel(
      id: id,
      name: name,
      category: category,
      imageUrl: 'https://via.placeholder.com/300x400?text=$name',
      price: price,
      brand: 'StyleBrand',
      affiliateUrl: '$_affiliateBaseUrl/$id',
      provider: 'MyAffiliate',
      colors: [color],
      rating: 4.2,
      description: 'High-quality $name perfect for your wardrobe.',
    );
  }

  // Build affiliate URL
  String buildAffiliateUrl({
    required String productId,
    required String provider,
  }) {
    // Different providers might have different URL structures
    switch (provider.toLowerCase()) {
      case 'amazon':
        final tag = dotenv.env['AMAZON_AFFILIATE_TAG'] ?? '';
        return 'https://amazon.com/dp/$productId?tag=$tag';
      case 'myntra':
        final id = dotenv.env['MYNTRA_AFFILIATE_ID'] ?? '';
        return 'https://myntra.com/product/$productId?aid=$id';
      default:
        return '$_affiliateBaseUrl/$productId';
    }
  }
}
