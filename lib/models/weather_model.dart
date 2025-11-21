import 'package:equatable/equatable.dart';

class WeatherModel extends Equatable {
  final String cityName;
  final String condition; // Clear, Clouds, Rain, etc.
  final String description; // clear sky, few clouds, etc.
  final double temperature; // in Celsius
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String icon; // weather icon code
  final DateTime timestamp;

  const WeatherModel({
    required this.cityName,
    required this.condition,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.timestamp,
  });

  // From API JSON
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      condition: json['weather'][0]['main'] ?? '',
      description: json['weather'][0]['description'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      icon: json['weather'][0]['icon'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  // Get weather icon URL
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  // Get temperature in Fahrenheit
  double get temperatureF => (temperature * 9 / 5) + 32;

  // Get clothing recommendation based on temperature
  String get clothingRecommendation {
    if (temperature < 10) {
      return 'Heavy jacket, warm layers';
    } else if (temperature < 15) {
      return 'Light jacket or sweater';
    } else if (temperature < 20) {
      return 'Long sleeves, light layers';
    } else if (temperature < 25) {
      return 'T-shirt, comfortable clothes';
    } else {
      return 'Light, breathable fabrics';
    }
  }

  // Get suitable season based on temperature
  String get suitableSeason {
    if (temperature < 15) {
      return 'Winter';
    } else if (temperature < 25) {
      return 'Spring';
    } else {
      return 'Summer';
    }
  }

  // Check if it's raining
  bool get isRaining =>
      condition == 'Rain' || condition == 'Drizzle' || condition == 'Thunderstorm';

  // Check if it's cold
  bool get isCold => temperature < 15;

  // Check if it's hot
  bool get isHot => temperature > 28;

  @override
  List<Object?> get props => [
        cityName,
        condition,
        description,
        temperature,
        feelsLike,
        humidity,
        windSpeed,
        icon,
        timestamp,
      ];
}
