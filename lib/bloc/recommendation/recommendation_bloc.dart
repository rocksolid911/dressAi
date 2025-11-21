import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dressai/models/weather_model.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import '../../models/recommendation_log_model.dart';
import '../../services/weather_service.dart';
import '../../services/ai_stylist_service.dart';
import '../../services/affiliate_recommendation_service.dart';
import '../../core/constants/app_constants.dart';
import 'recommendation_event.dart';
import 'recommendation_state.dart';

class RecommendationBloc extends Bloc<RecommendationEvent, RecommendationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WeatherService _weatherService = WeatherService();
  final AiStylistService _aiService = AiStylistService();
  final AffiliateRecommendationService _affiliateService =
      AffiliateRecommendationService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  RecommendationBloc() : super(const RecommendationInitial()) {
    on<FetchWeather>(_onFetchWeather);
    on<FetchWeatherByCoordinates>(_onFetchWeatherByCoordinates);
    on<GenerateDailyRecommendations>(_onGenerateDailyRecommendations);
    on<GenerateOccasionRecommendations>(_onGenerateOccasionRecommendations);
    on<GenerateFromPrompt>(_onGenerateFromPrompt);
    on<GetShoppingRecommendationsForItem>(_onGetShoppingRecommendationsForItem);
    on<GetWardrobeGapRecommendations>(_onGetWardrobeGapRecommendations);
    on<GetOccasionShoppingRecommendations>(_onGetOccasionShoppingRecommendations);
    on<LikeRecommendation>(_onLikeRecommendation);
    on<TrackAffiliateClick>(_onTrackAffiliateClick);
    on<ClearRecommendations>(_onClearRecommendations);
    on<ClearShoppingRecommendations>(_onClearShoppingRecommendations);
    on<ClearRecommendationError>(_onClearRecommendationError);
  }

  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      final weather = await _weatherService.getWeatherByCity(event.cityName);
      if (weather != null) {
        emit(WeatherLoaded(weather));
      } else {
        emit(const RecommendationError('Failed to fetch weather'));
      }
    } catch (e) {
      emit(RecommendationError('Failed to fetch weather: ${e.toString()}'));
    }
  }

  Future<void> _onFetchWeatherByCoordinates(
    FetchWeatherByCoordinates event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      final weather = await _weatherService.getWeatherByCoordinates(
        latitude: event.latitude,
        longitude: event.longitude,
      );
      if (weather != null) {
        emit(WeatherLoaded(weather));
      } else {
        emit(const RecommendationError('Failed to fetch weather'));
      }
    } catch (e) {
      emit(RecommendationError('Failed to fetch weather: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateDailyRecommendations(
    GenerateDailyRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      emit(const RecommendationLoading());

      // Fetch weather if city provided
      WeatherModel? weather;
      if (event.cityName != null) {
        weather = await _weatherService.getWeatherByCity(event.cityName!);
      }

      // Create context
      final context = RecommendationContext(
        weather: weather?.condition,
        temperature: weather?.temperature,
      );

      // Generate recommendations
      final recommendations = await _aiService.generateRecommendations(
        wardrobe: event.wardrobe,
        context: context,
        maxRecommendations: 5,
      );

      // Save recommendation log
      await _saveRecommendationLog(event.userId, context);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventViewRecommendation,
        parameters: {'type': 'daily', 'count': recommendations.length},
      );

      emit(RecommendationLoaded(
        recommendations: recommendations,
        currentWeather: weather,
      ));
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onGenerateOccasionRecommendations(
    GenerateOccasionRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      emit(const RecommendationLoading());

      // Fetch weather if city provided
      WeatherModel? weather;
      if (event.cityName != null) {
        weather = await _weatherService.getWeatherByCity(event.cityName!);
      }

      // Create context
      final context = RecommendationContext(
        occasion: event.occasion,
        mood: event.mood,
        weather: weather?.condition,
        temperature: weather?.temperature,
      );

      // Generate recommendations
      final recommendations = await _aiService.generateRecommendations(
        wardrobe: event.wardrobe,
        context: context,
        maxRecommendations: 5,
      );

      // Save recommendation log
      await _saveRecommendationLog(event.userId, context);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventViewRecommendation,
        parameters: {
          'type': 'occasion',
          'occasion': event.occasion,
          'count': recommendations.length
        },
      );

      emit(RecommendationLoaded(
        recommendations: recommendations,
        currentWeather: weather,
      ));
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onGenerateFromPrompt(
    GenerateFromPrompt event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      emit(const RecommendationLoading());

      // Parse prompt with AI
      var context = await _aiService.parseNaturalLanguageInput(event.prompt);

      // Fetch weather if city provided
      WeatherModel? weather;
      if (event.cityName != null) {
        weather = await _weatherService.getWeatherByCity(event.cityName!);
      }

      // Add weather to context
      context = RecommendationContext(
        occasion: context.occasion,
        mood: context.mood,
        weather: weather?.condition,
        temperature: weather?.temperature,
        userPrompt: event.prompt,
      );

      // Generate recommendations
      final recommendations = await _aiService.generateRecommendations(
        wardrobe: event.wardrobe,
        context: context,
        maxRecommendations: 5,
      );

      // Save recommendation log
      await _saveRecommendationLog(event.userId, context);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventViewRecommendation,
        parameters: {'type': 'prompt', 'count': recommendations.length},
      );

      emit(RecommendationLoaded(
        recommendations: recommendations,
        currentWeather: weather,
      ));
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onGetShoppingRecommendationsForItem(
    GetShoppingRecommendationsForItem event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      emit(const RecommendationLoading());

      final shoppingRecommendations =
          await _affiliateService.getRecommendationsForItem(event.item);

      final currentState = state is RecommendationLoaded
          ? (state as RecommendationLoaded)
          : const RecommendationLoaded(recommendations: []);

      emit(currentState.copyWith(
        shoppingRecommendations: shoppingRecommendations,
      ));
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onGetWardrobeGapRecommendations(
    GetWardrobeGapRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      emit(const RecommendationLoading());

      final shoppingRecommendations =
          await _affiliateService.getWardrobeGapRecommendations(event.wardrobe);

      final currentState = state is RecommendationLoaded
          ? (state as RecommendationLoaded)
          : const RecommendationLoaded(recommendations: []);

      emit(currentState.copyWith(
        shoppingRecommendations: shoppingRecommendations,
      ));
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onGetOccasionShoppingRecommendations(
    GetOccasionShoppingRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      emit(const RecommendationLoading());

      final shoppingRecommendations =
          await _affiliateService.getOccasionRecommendations(
        occasion: event.occasion,
        existingWardrobe: event.wardrobe,
      );

      final currentState = state is RecommendationLoaded
          ? (state as RecommendationLoaded)
          : const RecommendationLoaded(recommendations: []);

      emit(currentState.copyWith(
        shoppingRecommendations: shoppingRecommendations,
      ));
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onLikeRecommendation(
    LikeRecommendation event,
    Emitter<RecommendationState> emit,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.recommendationLogsCollection)
          .doc(event.logId)
          .update({'liked': true});

      // Log analytics
      await _analytics.logEvent(name: AppConstants.eventLikeOutfit);
    } catch (e) {
      emit(RecommendationError(e.toString()));
    }
  }

  Future<void> _onTrackAffiliateClick(
    TrackAffiliateClick event,
    Emitter<RecommendationState> emit,
  ) async {
    await _analytics.logEvent(
      name: AppConstants.eventClickAffiliate,
      parameters: {'product_id': event.productId, 'provider': event.provider},
    );
  }

  Future<void> _onClearRecommendations(
    ClearRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    if (state is RecommendationLoaded) {
      final currentState = state as RecommendationLoaded;
      emit(currentState.copyWith(recommendations: []));
    }
  }

  Future<void> _onClearShoppingRecommendations(
    ClearShoppingRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    if (state is RecommendationLoaded) {
      final currentState = state as RecommendationLoaded;
      emit(currentState.copyWith(shoppingRecommendations: []));
    }
  }

  Future<void> _onClearRecommendationError(
    ClearRecommendationError event,
    Emitter<RecommendationState> emit,
  ) async {
    if (state is RecommendationError) {
      emit(const RecommendationInitial());
    }
  }

  // Save recommendation log
  Future<void> _saveRecommendationLog(
    String userId,
    RecommendationContext context,
  ) async {
    try {
      final recommendations = state is RecommendationLoaded
          ? (state as RecommendationLoaded).recommendations
          : <OutfitRecommendation>[];

      final log = RecommendationLogModel(
        id: '',
        userId: userId,
        inputContext: context,
        suggestedOutfitIds: [],
        aiExplanation: recommendations.isNotEmpty
            ? recommendations.first.explanation
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
}
