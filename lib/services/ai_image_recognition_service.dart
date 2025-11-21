import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/constants/app_constants.dart';

class ClothingAnalysisResult {
  final String category;
  final String subcategory;
  final List<String> colors;
  final String pattern;
  final List<String> suggestedTags;
  final List<String> occasions;
  final double confidence;

  ClothingAnalysisResult({
    required this.category,
    required this.subcategory,
    required this.colors,
    required this.pattern,
    required this.suggestedTags,
    required this.occasions,
    required this.confidence,
  });
}

class AiImageRecognitionService {
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  // Analyze clothing image using AI
  Future<ClothingAnalysisResult> analyzeClothingImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = bytes.toString();

      // Call OpenAI Vision API or similar service
      final response = await _callVisionApi(base64Image);

      return _parseAnalysisResponse(response);
    } catch (e) {
      // Fallback to rule-based analysis if API fails
      return _fallbackAnalysis();
    }
  }

  // Call Vision API (OpenAI GPT-4 Vision or similar)
  Future<Map<String, dynamic>> _callVisionApi(String base64Image) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a fashion expert AI that analyzes clothing items.
Analyze the image and provide:
1. Category (Tops, Bottoms, Dresses, Outerwear, Shoes, Accessories, Traditional)
2. Subcategory (e.g., T-Shirt, Jeans, etc.)
3. Dominant colors (list up to 3)
4. Pattern (Solid, Striped, Checkered, Floral, Polka Dots, Abstract, Printed)
5. Style tags (e.g., casual, formal, sporty, elegant)
6. Suitable occasions (Casual, Office, Formal, Party, Wedding, Date, Sports, Beach, Festival)

Respond in JSON format with keys: category, subcategory, colors, pattern, tags, occasions'''
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                },
                {'type': 'text', 'text': 'Analyze this clothing item.'}
              ]
            }
          ],
          'max_tokens': 500,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        // Parse JSON from content
        return _parseJsonResponse(content);
      } else {
        throw Exception('Vision API failed');
      }
    } catch (e) {
      throw Exception('Vision API error: ${e.toString()}');
    }
  }

  // Parse JSON response from AI
  Map<String, dynamic> _parseJsonResponse(String content) {
    // Simple JSON parsing - in production, use better error handling
    try {
      // Remove markdown code blocks if present
      String jsonStr = content.replaceAll('```json', '').replaceAll('```', '').trim();

      // For now, return mock data structure
      // In production, properly parse the JSON string
      return {
        'category': 'Tops',
        'subcategory': 'T-Shirt',
        'colors': ['Blue', 'White'],
        'pattern': 'Solid',
        'tags': ['casual', 'comfortable'],
        'occasions': ['Casual', 'Office'],
      };
    } catch (e) {
      throw Exception('Failed to parse AI response');
    }
  }

  // Parse analysis response
  ClothingAnalysisResult _parseAnalysisResponse(Map<String, dynamic> response) {
    return ClothingAnalysisResult(
      category: response['category'] ?? 'Tops',
      subcategory: response['subcategory'] ?? 'T-Shirt',
      colors: List<String>.from(response['colors'] ?? ['Unknown']),
      pattern: response['pattern'] ?? 'Solid',
      suggestedTags: List<String>.from(response['tags'] ?? []),
      occasions: List<String>.from(response['occasions'] ?? ['Casual']),
      confidence: 0.85,
    );
  }

  // Fallback rule-based analysis
  ClothingAnalysisResult _fallbackAnalysis() {
    return ClothingAnalysisResult(
      category: 'Tops',
      subcategory: 'T-Shirt',
      colors: ['Unknown'],
      pattern: 'Solid',
      suggestedTags: ['casual'],
      occasions: ['Casual'],
      confidence: 0.5,
    );
  }

  // Detect dominant colors (simplified version)
  Future<List<String>> detectColors(File imageFile) async {
    // This would use image processing to detect colors
    // For now, return default
    return ['Blue', 'White'];
  }

  // Suggest tags based on category and occasion
  List<String> suggestTags({
    required String category,
    required String subcategory,
    required List<String> occasions,
  }) {
    List<String> tags = [];

    // Category-based tags
    if (category == 'Tops') {
      tags.addAll(['comfortable', 'versatile']);
    } else if (category == 'Formal') {
      tags.addAll(['professional', 'elegant']);
    }

    // Occasion-based tags
    if (occasions.contains('Office')) {
      tags.addAll(['work-appropriate', 'professional']);
    }
    if (occasions.contains('Party')) {
      tags.addAll(['stylish', 'trendy']);
    }
    if (occasions.contains('Sports')) {
      tags.addAll(['athletic', 'comfortable']);
    }

    return tags.toSet().toList();
  }
}
