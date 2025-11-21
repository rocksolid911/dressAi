import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
  final String _baseUrl = dotenv.env['WEATHER_API_BASE_URL'] ??
      'https://api.openweathermap.org/data/2.5';

  // Get current weather by city name
  Future<WeatherModel> getWeatherByCity(String cityName) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Weather service error: ${e.toString()}');
    }
  }

  // Get current weather by coordinates
  Future<WeatherModel> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Weather service error: ${e.toString()}');
    }
  }

  // Get 5-day forecast
  Future<List<WeatherModel>> getForecast(String cityName) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> forecastList = response.data['list'];
        return forecastList
            .map((json) => WeatherModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Weather service error: ${e.toString()}');
    }
  }

  // Get clothing recommendations based on weather
  Map<String, dynamic> getClothingRecommendations(WeatherModel weather) {
    List<String> recommendations = [];
    List<String> warnings = [];

    // Temperature-based recommendations
    if (weather.temperature < 10) {
      recommendations.addAll([
        'Heavy jacket or coat',
        'Warm layers (sweater, thermal)',
        'Scarf and gloves',
        'Warm pants',
        'Boots or closed shoes',
      ]);
    } else if (weather.temperature < 15) {
      recommendations.addAll([
        'Light jacket or cardigan',
        'Long-sleeve top',
        'Jeans or warm pants',
        'Comfortable shoes',
      ]);
    } else if (weather.temperature < 20) {
      recommendations.addAll([
        'Light sweater or hoodie',
        'T-shirt or long-sleeve',
        'Jeans or casual pants',
        'Sneakers',
      ]);
    } else if (weather.temperature < 25) {
      recommendations.addAll([
        'T-shirt or light top',
        'Shorts or light pants',
        'Comfortable footwear',
      ]);
    } else {
      recommendations.addAll([
        'Light, breathable fabrics',
        'Shorts or light dress',
        'Sandals or light shoes',
        'Sun hat or cap',
      ]);
    }

    // Weather condition-based recommendations
    if (weather.isRaining) {
      recommendations.addAll([
        'Raincoat or umbrella',
        'Water-resistant shoes',
      ]);
      warnings.add('It\'s raining - bring rain protection!');
    }

    if (weather.condition == 'Snow') {
      recommendations.addAll([
        'Heavy winter coat',
        'Waterproof boots',
        'Warm accessories',
      ]);
      warnings.add('Snowy conditions - dress warmly!');
    }

    if (weather.temperature > 30) {
      warnings.add('Very hot - stay hydrated and wear light colors!');
    }

    if (weather.temperature < 5) {
      warnings.add('Very cold - layer up and protect exposed skin!');
    }

    if (weather.windSpeed > 10) {
      warnings.add('Windy conditions - secure loose clothing!');
    }

    return {
      'recommendations': recommendations,
      'warnings': warnings,
      'suitable_seasons': _getSuitableSeasons(weather.temperature),
      'avoid_fabrics': _getAvoidFabrics(weather),
      'preferred_fabrics': _getPreferredFabrics(weather),
    };
  }

  List<String> _getSuitableSeasons(double temperature) {
    if (temperature < 15) {
      return ['Winter', 'All Season'];
    } else if (temperature < 25) {
      return ['Spring', 'Autumn', 'All Season'];
    } else {
      return ['Summer', 'All Season'];
    }
  }

  List<String> _getAvoidFabrics(WeatherModel weather) {
    List<String> avoid = [];

    if (weather.temperature > 28) {
      avoid.addAll(['Wool', 'Velvet', 'Heavy fabrics']);
    }

    if (weather.isRaining) {
      avoid.addAll(['Silk', 'Suede']);
    }

    return avoid;
  }

  List<String> _getPreferredFabrics(WeatherModel weather) {
    List<String> preferred = [];

    if (weather.temperature < 15) {
      preferred.addAll(['Wool', 'Fleece', 'Denim']);
    } else if (weather.temperature > 25) {
      preferred.addAll(['Cotton', 'Linen', 'Light fabrics']);
    } else {
      preferred.addAll(['Cotton', 'Polyester', 'Denim']);
    }

    if (weather.isRaining) {
      preferred.addAll(['Waterproof fabrics', 'Synthetic materials']);
    }

    return preferred;
  }
}
