import 'package:equatable/equatable.dart';
import '../../models/clothing_item_model.dart';

abstract class RecommendationEvent extends Equatable {
  const RecommendationEvent();

  @override
  List<Object?> get props => [];
}

class FetchWeather extends RecommendationEvent {
  final String cityName;

  const FetchWeather(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

class FetchWeatherByCoordinates extends RecommendationEvent {
  final double latitude;
  final double longitude;

  const FetchWeatherByCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class GenerateDailyRecommendations extends RecommendationEvent {
  final String userId;
  final List<ClothingItemModel> wardrobe;
  final String? cityName;

  const GenerateDailyRecommendations({
    required this.userId,
    required this.wardrobe,
    this.cityName,
  });

  @override
  List<Object?> get props => [userId, wardrobe, cityName];
}

class GenerateOccasionRecommendations extends RecommendationEvent {
  final String userId;
  final List<ClothingItemModel> wardrobe;
  final String occasion;
  final String? mood;
  final String? cityName;

  const GenerateOccasionRecommendations({
    required this.userId,
    required this.wardrobe,
    required this.occasion,
    this.mood,
    this.cityName,
  });

  @override
  List<Object?> get props => [userId, wardrobe, occasion, mood, cityName];
}

class GenerateFromPrompt extends RecommendationEvent {
  final String userId;
  final List<ClothingItemModel> wardrobe;
  final String prompt;
  final String? cityName;

  const GenerateFromPrompt({
    required this.userId,
    required this.wardrobe,
    required this.prompt,
    this.cityName,
  });

  @override
  List<Object?> get props => [userId, wardrobe, prompt, cityName];
}

class GetShoppingRecommendationsForItem extends RecommendationEvent {
  final ClothingItemModel item;

  const GetShoppingRecommendationsForItem(this.item);

  @override
  List<Object?> get props => [item];
}

class GetWardrobeGapRecommendations extends RecommendationEvent {
  final List<ClothingItemModel> wardrobe;

  const GetWardrobeGapRecommendations(this.wardrobe);

  @override
  List<Object?> get props => [wardrobe];
}

class GetOccasionShoppingRecommendations extends RecommendationEvent {
  final String occasion;
  final List<ClothingItemModel> wardrobe;

  const GetOccasionShoppingRecommendations({
    required this.occasion,
    required this.wardrobe,
  });

  @override
  List<Object?> get props => [occasion, wardrobe];
}

class LikeRecommendation extends RecommendationEvent {
  final String logId;

  const LikeRecommendation(this.logId);

  @override
  List<Object?> get props => [logId];
}

class TrackAffiliateClick extends RecommendationEvent {
  final String productId;
  final String provider;

  const TrackAffiliateClick({
    required this.productId,
    required this.provider,
  });

  @override
  List<Object?> get props => [productId, provider];
}

class ClearRecommendations extends RecommendationEvent {
  const ClearRecommendations();
}

class ClearShoppingRecommendations extends RecommendationEvent {
  const ClearShoppingRecommendations();
}

class ClearRecommendationError extends RecommendationEvent {
  const ClearRecommendationError();
}
