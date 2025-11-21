import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/clothing_item_model.dart';
import '../services/storage_service.dart';
import '../services/ai_image_recognition_service.dart';
import '../core/constants/app_constants.dart';

class WardrobeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final AiImageRecognitionService _aiService = AiImageRecognitionService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  List<ClothingItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ClothingItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get items by category
  List<ClothingItemModel> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Get favorite items
  List<ClothingItemModel> get favoriteItems {
    return _items.where((item) => item.isFavorite).toList();
  }

  // Get items by season
  List<ClothingItemModel> getItemsBySeason(String season) {
    return _items.where((item) =>
        item.season == season || item.season == 'All Season').toList();
  }

  // Load wardrobe items
  Future<void> loadWardrobeItems(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _items = snapshot.docs
          .map((doc) => ClothingItemModel.fromFirestore(doc))
          .toList();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add clothing item
  Future<ClothingItemModel?> addClothingItem({
    required String userId,
    required File imageFile,
    required String category,
    required String subcategory,
    required String color,
    String pattern = 'Solid',
    String? fabric,
    String season = 'All Season',
    List<String> tags = const [],
    List<String> occasionTags = const [],
    String? brand,
    double? price,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload image
      final imageUrl = await _storageService.uploadClothingImage(
        imageFile: imageFile,
        userId: userId,
      );

      // Create clothing item
      final item = ClothingItemModel(
        id: '',
        userId: userId,
        imageUrl: imageUrl,
        category: category,
        subcategory: subcategory,
        color: color,
        pattern: pattern,
        fabric: fabric,
        season: season,
        tags: tags,
        occasionTags: occasionTags,
        brand: brand,
        price: price,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .add(item.toFirestore());

      final savedItem = item.copyWith(id: docRef.id);
      _items.insert(0, savedItem);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventAddItem,
        parameters: {'category': category, 'subcategory': subcategory},
      );

      _isLoading = false;
      _error = null;
      notifyListeners();

      return savedItem;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Analyze image with AI
  Future<ClothingAnalysisResult?> analyzeImage(File imageFile) async {
    try {
      return await _aiService.analyzeClothingImage(imageFile);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update clothing item
  Future<bool> updateClothingItem(ClothingItemModel item) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedItem = item.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .doc(item.id)
          .update(updatedItem.toFirestore());

      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete clothing item
  Future<bool> deleteClothingItem(ClothingItemModel item) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete from Firestore
      await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .doc(item.id)
          .delete();

      // Delete image from storage
      await _storageService.deleteImage(item.imageUrl);

      _items.removeWhere((i) => i.id == item.id);

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(ClothingItemModel item) async {
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    await updateClothingItem(updatedItem);
  }

  // Mark as worn
  Future<void> markAsWorn(ClothingItemModel item) async {
    final updatedItem = item.copyWith(lastWornAt: DateTime.now());
    await updateClothingItem(updatedItem);
  }

  // Search items
  List<ClothingItemModel> searchItems(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _items.where((item) {
      return item.category.toLowerCase().contains(lowercaseQuery) ||
          item.subcategory.toLowerCase().contains(lowercaseQuery) ||
          item.color.toLowerCase().contains(lowercaseQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
          (item.brand?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Filter items
  List<ClothingItemModel> filterItems({
    String? category,
    String? color,
    String? season,
    String? occasion,
    bool? isFavorite,
  }) {
    return _items.where((item) {
      if (category != null && item.category != category) return false;
      if (color != null && item.color != color) return false;
      if (season != null &&
          item.season != season &&
          item.season != 'All Season') {
        return false;
      }
      if (occasion != null && !item.occasionTags.contains(occasion)) {
        return false;
      }
      if (isFavorite != null && item.isFavorite != isFavorite) return false;
      return true;
    }).toList();
  }

  // Get wardrobe statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total': _items.length,
      'categories': _getCategoryCounts(),
      'mostWornColor': _getMostWornColor(),
      'leastWornItems': _getLeastWornItems(),
      'favorites': favoriteItems.length,
    };
  }

  Map<String, int> _getCategoryCounts() {
    Map<String, int> counts = {};
    for (var item in _items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  String _getMostWornColor() {
    Map<String, int> colorCounts = {};
    for (var item in _items) {
      if (item.lastWornAt != null) {
        colorCounts[item.color] = (colorCounts[item.color] ?? 0) + 1;
      }
    }

    if (colorCounts.isEmpty) return 'N/A';

    return colorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<ClothingItemModel> _getLeastWornItems() {
    final sortedItems = List<ClothingItemModel>.from(_items);
    sortedItems.sort((a, b) {
      if (a.lastWornAt == null && b.lastWornAt == null) return 0;
      if (a.lastWornAt == null) return -1;
      if (b.lastWornAt == null) return 1;
      return a.lastWornAt!.compareTo(b.lastWornAt!);
    });
    return sortedItems.take(5).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
