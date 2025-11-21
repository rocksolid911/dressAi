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

  // From OpenWeatherMap API JSON (legacy support)
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

  // From Open-Meteo API JSON (free, no API key needed)
  factory WeatherModel.fromOpenMeteoJson(Map<String, dynamic> json, String cityName) {
    final current = json['current'];
    final weatherCode = current['weather_code'] as int;
    final weatherInfo = _getWeatherInfoFromCode(weatherCode);

    return WeatherModel(
      cityName: cityName,
      condition: weatherInfo['condition']!,
      description: weatherInfo['description']!,
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['temperature_2m'] as num).toDouble(), // Open-Meteo doesn't provide feels_like
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      icon: weatherInfo['icon']!,
      timestamp: DateTime.now(),
    );
  }

  // From Open-Meteo forecast data
  factory WeatherModel.fromOpenMeteoForecast(
    String cityName,
    String dateStr,
    double temperature,
    int weatherCode,
    double windSpeed,
  ) {
    final weatherInfo = _getWeatherInfoFromCode(weatherCode);

    return WeatherModel(
      cityName: cityName,
      condition: weatherInfo['condition']!,
      description: weatherInfo['description']!,
      temperature: temperature,
      feelsLike: temperature,
      humidity: 50, // Default value for forecast
      windSpeed: windSpeed,
      icon: weatherInfo['icon']!,
      timestamp: DateTime.parse(dateStr),
    );
  }

  // Map Open-Meteo WMO weather codes to weather conditions
  static Map<String, String> _getWeatherInfoFromCode(int code) {
    switch (code) {
      case 0:
        return {'condition': 'Clear', 'description': 'Clear sky', 'icon': '01d'};
      case 1:
        return {'condition': 'Clear', 'description': 'Mainly clear', 'icon': '01d'};
      case 2:
        return {'condition': 'Clouds', 'description': 'Partly cloudy', 'icon': '02d'};
      case 3:
        return {'condition': 'Clouds', 'description': 'Overcast', 'icon': '03d'};
      case 45:
      case 48:
        return {'condition': 'Fog', 'description': 'Foggy', 'icon': '50d'};
      case 51:
      case 53:
      case 55:
        return {'condition': 'Drizzle', 'description': 'Drizzle', 'icon': '09d'};
      case 61:
      case 63:
      case 65:
        return {'condition': 'Rain', 'description': 'Rain', 'icon': '10d'};
      case 66:
      case 67:
        return {'condition': 'Rain', 'description': 'Freezing rain', 'icon': '13d'};
      case 71:
      case 73:
      case 75:
        return {'condition': 'Snow', 'description': 'Snow', 'icon': '13d'};
      case 77:
        return {'condition': 'Snow', 'description': 'Snow grains', 'icon': '13d'};
      case 80:
      case 81:
      case 82:
        return {'condition': 'Rain', 'description': 'Rain showers', 'icon': '09d'};
      case 85:
      case 86:
        return {'condition': 'Snow', 'description': 'Snow showers', 'icon': '13d'};
      case 95:
        return {'condition': 'Thunderstorm', 'description': 'Thunderstorm', 'icon': '11d'};
      case 96:
      case 99:
        return {'condition': 'Thunderstorm', 'description': 'Thunderstorm with hail', 'icon': '11d'};
      default:
        return {'condition': 'Unknown', 'description': 'Unknown', 'icon': '01d'};
    }
  }

  // Get weather icon URL (using a generic icon service since we're not using OpenWeatherMap anymore)
  String get iconUrl {
    // Map to emoji-based weather icons for simplicity
    switch (condition) {
      case 'Clear':
        return '☀️';
      case 'Clouds':
        return '☁️';
      case 'Rain':
        return '🌧️';
      case 'Drizzle':
        return '🌦️';
      case 'Thunderstorm':
        return '⛈️';
      case 'Snow':
        return '❄️';
      case 'Fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

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
