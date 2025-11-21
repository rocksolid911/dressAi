import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';
import '../models/recommendation_log_model.dart';
import '../models/shopping_item_model.dart';
import '../services/weather_service.dart';
import '../services/ai_stylist_service.dart';
import '../services/affiliate_recommendation_service.dart';
import '../core/constants/app_constants.dart';

class RecommendationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WeatherService _weatherService = WeatherService();
  final AiStylistService _aiService = AiStylistService();
  final AffiliateRecommendationService _affiliateService =
      AffiliateRecommendationService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  List<OutfitRecommendation> _recommendations = [];
  WeatherModel? _currentWeather;
  List<ShoppingItemModel> _shoppingRecommendations = [];
  bool _isLoading = false;
  String? _error;

  List<OutfitRecommendation> get recommendations => _recommendations;
  WeatherModel? get currentWeather => _currentWeather;
  List<ShoppingItemModel> get shoppingRecommendations => _shoppingRecommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch weather
  Future<void> fetchWeather(String cityName) async {
    try {
      _currentWeather = await _weatherService.getWeatherByCity(cityName);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch weather: ${e.toString()}';
      notifyListeners();
    }
  }

  // Fetch weather by coordinates
  Future<void> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      _currentWeather = await _weatherService.getWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch weather: ${e.toString()}';
      notifyListeners();
    }
  }

  // Generate daily recommendations
  Future<void> generateDailyRecommendations({
    required String userId,
    required List<ClothingItemModel> wardrobe,
    String? cityName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch weather if city provided
      if (cityName != null) {
        await fetchWeather(cityName);
      }

      // Create context
      final context = RecommendationContext(
        weather: _currentWeather?.condition,
        temperature: _currentWeather?.temperature,
      );

      // Generate recommendations
      _recommendations = await _aiService.generateRecommendations(
        wardrobe: wardrobe,
        context: context,
        maxRecommendations: 5,
      );

      // Save recommendation log
      await _saveRecommendationLog(userId, context);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventViewRecommendation,
        parameters: {'type': 'daily', 'count': _recommendations.length},
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate occasion-based recommendations
  Future<void> generateOccasionRecommendations({
    required String userId,
    required List<ClothingItemModel> wardrobe,
    required String occasion,
    String? mood,
    String? cityName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch weather if city provided
      if (cityName != null && _currentWeather == null) {
        await fetchWeather(cityName);
      }

      // Create context
      final context = RecommendationContext(
        occasion: occasion,
        mood: mood,
        weather: _currentWeather?.condition,
        temperature: _currentWeather?.temperature,
      );

      // Generate recommendations
      _recommendations = await _aiService.generateRecommendations(
        wardrobe: wardrobe,
        context: context,
        maxRecommendations: 5,
      );

      // Save recommendation log
      await _saveRecommendationLog(userId, context);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventViewRecommendation,
        parameters: {
          'type': 'occasion',
          'occasion': occasion,
          'count': _recommendations.length
        },
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate recommendations from natural language
  Future<void> generateFromPrompt({
    required String userId,
    required List<ClothingItemModel> wardrobe,
    required String prompt,
    String? cityName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Parse prompt with AI
      var context = await _aiService.parseNaturalLanguageInput(prompt);

      // Fetch weather if city provided
      if (cityName != null && _currentWeather == null) {
        await fetchWeather(cityName);
      }

      // Add weather to context
      context = RecommendationContext(
        occasion: context.occasion,
        mood: context.mood,
        weather: _currentWeather?.condition,
        temperature: _currentWeather?.temperature,
        userPrompt: prompt,
      );

      // Generate recommendations
      _recommendations = await _aiService.generateRecommendations(
        wardrobe: wardrobe,
        context: context,
        maxRecommendations: 5,
      );

      // Save recommendation log
      await _saveRecommendationLog(userId, context);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventViewRecommendation,
        parameters: {'type': 'prompt', 'count': _recommendations.length},
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get shopping recommendations for item
  Future<void> getShoppingRecommendationsForItem(
    ClothingItemModel item,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      _shoppingRecommendations =
          await _affiliateService.getRecommendationsForItem(item);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get wardrobe gap recommendations
  Future<void> getWardrobeGapRecommendations(
    List<ClothingItemModel> wardrobe,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      _shoppingRecommendations =
          await _affiliateService.getWardrobeGapRecommendations(wardrobe);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get occasion-based shopping recommendations
  Future<void> getOccasionShoppingRecommendations({
    required String occasion,
    required List<ClothingItemModel> wardrobe,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      _shoppingRecommendations =
          await _affiliateService.getOccasionRecommendations(
        occasion: occasion,
        existingWardrobe: wardrobe,
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save recommendation log
  Future<void> _saveRecommendationLog(
    String userId,
    RecommendationContext context,
  ) async {
    try {
      final log = RecommendationLogModel(
        id: '',
        userId: userId,
        inputContext: context,
        suggestedOutfitIds: [],
        aiExplanation: _recommendations.isNotEmpty
            ? _recommendations.first.explanation
            : null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.recommendationLogsCollection)
          .add(log.toFirestore());
    } catch (e) {
      // Silently fail - logging shouldn't break the flow
      debugPrint('Failed to save recommendation log: ${e.toString()}');
    }
  }

  // Like recommendation
  Future<void> likeRecommendation(String logId) async {
    try {
      await _firestore
          .collection(AppConstants.recommendationLogsCollection)
          .doc(logId)
          .update({'liked': true});

      // Log analytics
      await _analytics.logEvent(name: AppConstants.eventLikeOutfit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Track affiliate click
  Future<void> trackAffiliateClick({
    required String productId,
    required String provider,
  }) async {
    await _analytics.logEvent(
      name: AppConstants.eventClickAffiliate,
      parameters: {'product_id': productId, 'provider': provider},
    );
  }

  // Clear recommendations
  void clearRecommendations() {
    _recommendations = [];
    notifyListeners();
  }

  // Clear shopping recommendations
  void clearShoppingRecommendations() {
    _shoppingRecommendations = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
