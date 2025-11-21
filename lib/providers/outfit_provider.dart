import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/outfit_model.dart';
import '../models/clothing_item_model.dart';
import '../core/constants/app_constants.dart';

class OutfitProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  List<OutfitModel> _outfits = [];
  bool _isLoading = false;
  String? _error;

  List<OutfitModel> get outfits => _outfits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get favorite outfits
  List<OutfitModel> get favoriteOutfits {
    return _outfits.where((outfit) => outfit.isFavorite).toList();
  }

  // Get outfits by occasion
  List<OutfitModel> getOutfitsByOccasion(String occasion) {
    return _outfits.where((outfit) => outfit.occasion == occasion).toList();
  }

  // Get scheduled outfits
  List<OutfitModel> get scheduledOutfits {
    return _outfits.where((outfit) => outfit.scheduledDate != null).toList();
  }

  // Load outfits
  Future<void> loadOutfits(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection(AppConstants.outfitsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _outfits = snapshot.docs
          .map((doc) => OutfitModel.fromFirestore(doc))
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

  // Create outfit
  Future<OutfitModel?> createOutfit({
    required String userId,
    required String name,
    required List<String> clothingItemIds,
    List<String> tags = const [],
    String? occasion,
    String? description,
    DateTime? scheduledDate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final outfit = OutfitModel(
        id: '',
        userId: userId,
        name: name,
        clothingItemIds: clothingItemIds,
        tags: tags,
        occasion: occasion,
        description: description,
        scheduledDate: scheduledDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(AppConstants.outfitsCollection)
          .add(outfit.toFirestore());

      final savedOutfit = outfit.copyWith(id: docRef.id);
      _outfits.insert(0, savedOutfit);

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventCreateOutfit,
        parameters: {
          'item_count': clothingItemIds.length,
          'occasion': occasion ?? 'none',
        },
      );

      _isLoading = false;
      _error = null;
      notifyListeners();

      return savedOutfit;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update outfit
  Future<bool> updateOutfit(OutfitModel outfit) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedOutfit = outfit.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(AppConstants.outfitsCollection)
          .doc(outfit.id)
          .update(updatedOutfit.toFirestore());

      final index = _outfits.indexWhere((o) => o.id == outfit.id);
      if (index != -1) {
        _outfits[index] = updatedOutfit;
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

  // Delete outfit
  Future<bool> deleteOutfit(String outfitId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection(AppConstants.outfitsCollection)
          .doc(outfitId)
          .delete();

      _outfits.removeWhere((o) => o.id == outfitId);

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
  Future<void> toggleFavorite(OutfitModel outfit) async {
    final updatedOutfit = outfit.copyWith(isFavorite: !outfit.isFavorite);
    await updateOutfit(updatedOutfit);
  }

  // Schedule outfit
  Future<void> scheduleOutfit(OutfitModel outfit, DateTime date) async {
    final updatedOutfit = outfit.copyWith(scheduledDate: date);
    await updateOutfit(updatedOutfit);
  }

  // Get outfit with populated items
  Future<OutfitModel?> getOutfitWithItems(
    String outfitId,
    List<ClothingItemModel> wardrobe,
  ) async {
    try {
      final outfit = _outfits.firstWhere((o) => o.id == outfitId);

      final items = outfit.clothingItemIds
          .map((id) => wardrobe.firstWhere((item) => item.id == id))
          .toList();

      return outfit.copyWith(items: items);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get outfits for date
  List<OutfitModel> getOutfitsForDate(DateTime date) {
    return _outfits.where((outfit) {
      if (outfit.scheduledDate == null) return false;
      return outfit.scheduledDate!.year == date.year &&
          outfit.scheduledDate!.month == date.month &&
          outfit.scheduledDate!.day == date.day;
    }).toList();
  }

  // Get upcoming scheduled outfits
  List<OutfitModel> getUpcomingOutfits() {
    final now = DateTime.now();
    return _outfits
        .where((outfit) =>
            outfit.scheduledDate != null &&
            outfit.scheduledDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));
  }

  // Search outfits
  List<OutfitModel> searchOutfits(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _outfits.where((outfit) {
      return outfit.name.toLowerCase().contains(lowercaseQuery) ||
          (outfit.occasion?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          outfit.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
