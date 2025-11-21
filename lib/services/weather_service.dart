import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import '../models/weather_model.dart';

class WeatherService {
  final Dio _dio = Dio();
  // Open-Meteo is completely free and doesn't require an API key
  final String _baseUrl = 'https://api.open-meteo.com/v1';

  // Get coordinates from city name
  Future<Map<String, double>> _getCoordinatesFromCity(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      throw Exception('City not found');
    } catch (e) {
      throw Exception('Failed to find city: ${e.toString()}');
    }
  }

  // Get current weather by city name
  Future<WeatherModel> getWeatherByCity(String cityName) async {
    try {
      final coords = await _getCoordinatesFromCity(cityName);
      return await getWeatherByCoordinates(
        latitude: coords['latitude']!,
        longitude: coords['longitude']!,
        cityName: cityName,
      );
    } catch (e) {
      throw Exception('Weather service error: ${e.toString()}');
    }
  }

  // Get current weather by coordinates
  Future<WeatherModel> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String? cityName,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        // Get city name from coordinates if not provided
        String city = cityName ?? 'Unknown';
        if (cityName == null) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              latitude,
              longitude,
            );
            if (placemarks.isNotEmpty) {
              city = placemarks.first.locality ??
                     placemarks.first.administrativeArea ??
                     'Unknown';
            }
          } catch (e) {
            // Keep default city name if geocoding fails
          }
        }

        return WeatherModel.fromOpenMeteoJson(response.data, city);
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
      final coords = await _getCoordinatesFromCity(cityName);

      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': coords['latitude'],
          'longitude': coords['longitude'],
          'daily': 'temperature_2m_max,temperature_2m_min,weather_code,wind_speed_10m_max',
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        final dailyData = response.data['daily'];
        final List<String> times = List<String>.from(dailyData['time']);
        final List<double> tempMax = List<double>.from(
          dailyData['temperature_2m_max'].map((e) => e.toDouble())
        );
        final List<double> tempMin = List<double>.from(
          dailyData['temperature_2m_min'].map((e) => e.toDouble())
        );
        final List<int> weatherCodes = List<int>.from(dailyData['weather_code']);
        final List<double> windSpeeds = List<double>.from(
          dailyData['wind_speed_10m_max'].map((e) => e.toDouble())
        );

        List<WeatherModel> forecasts = [];
        for (int i = 0; i < times.length && i < 5; i++) {
          forecasts.add(WeatherModel.fromOpenMeteoForecast(
            cityName,
            times[i],
            (tempMax[i] + tempMin[i]) / 2, // Average temperature
            weatherCodes[i],
            windSpeeds[i],
          ));
        }
        return forecasts;
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
