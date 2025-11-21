import 'package:equatable/equatable.dart';
import '../../models/weather_model.dart';
import '../../models/shopping_item_model.dart';
import '../../services/ai_stylist_service.dart';

abstract class RecommendationState extends Equatable {
  const RecommendationState();

  @override
  List<Object?> get props => [];
}

class RecommendationInitial extends RecommendationState {
  const RecommendationInitial();
}

class RecommendationLoading extends RecommendationState {
  const RecommendationLoading();
}

class RecommendationLoaded extends RecommendationState {
  final List<OutfitRecommendation> recommendations;
  final WeatherModel? currentWeather;
  final List<ShoppingItemModel> shoppingRecommendations;

  const RecommendationLoaded({
    required this.recommendations,
    this.currentWeather,
    this.shoppingRecommendations = const [],
  });

  @override
  List<Object?> get props => [recommendations, currentWeather, shoppingRecommendations];

  RecommendationLoaded copyWith({
    List<OutfitRecommendation>? recommendations,
    WeatherModel? currentWeather,
    List<ShoppingItemModel>? shoppingRecommendations,
  }) {
    return RecommendationLoaded(
      recommendations: recommendations ?? this.recommendations,
      currentWeather: currentWeather ?? this.currentWeather,
      shoppingRecommendations: shoppingRecommendations ?? this.shoppingRecommendations,
    );
  }
}

class WeatherLoaded extends RecommendationState {
  final WeatherModel weather;

  const WeatherLoaded(this.weather);

  @override
  List<Object?> get props => [weather];
}

class ShoppingRecommendationsLoaded extends RecommendationState {
  final List<ShoppingItemModel> recommendations;

  const ShoppingRecommendationsLoaded(this.recommendations);

  @override
  List<Object?> get props => [recommendations];
}

class RecommendationError extends RecommendationState {
  final String message;

  const RecommendationError(this.message);

  @override
  List<Object?> get props => [message];
}
