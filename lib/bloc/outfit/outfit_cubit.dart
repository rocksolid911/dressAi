import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../models/outfit_model.dart';
import '../../models/clothing_item_model.dart';
import '../../core/constants/app_constants.dart';
import 'outfit_state.dart';

class OutfitCubit extends Cubit<OutfitState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  OutfitCubit() : super(const OutfitInitial());

  // Load outfits
  Future<void> loadOutfits(String userId) async {
    try {
      emit(const OutfitLoading());

      final snapshot = await _firestore
          .collection(AppConstants.outfitsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final outfits = snapshot.docs
          .map((doc) => OutfitModel.fromFirestore(doc))
          .toList();

      emit(OutfitLoaded(outfits));
    } catch (e) {
      emit(OutfitError(e.toString()));
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
      emit(const OutfitLoading());

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

      // Get current outfits
      final currentOutfits = state is OutfitLoaded
          ? (state as OutfitLoaded).outfits
          : <OutfitModel>[];

      final updatedOutfits = [savedOutfit, ...currentOutfits];

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventCreateOutfit,
        parameters: {
          'item_count': clothingItemIds.length,
          'occasion': occasion ?? 'none',
        },
      );

      emit(OutfitLoaded(updatedOutfits));
      return savedOutfit;
    } catch (e) {
      emit(OutfitError(e.toString()));
      return null;
    }
  }

  // Update outfit
  Future<bool> updateOutfit(OutfitModel outfit) async {
    try {
      emit(const OutfitLoading());

      final updatedOutfit = outfit.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(AppConstants.outfitsCollection)
          .doc(outfit.id)
          .update(updatedOutfit.toFirestore());

      final currentOutfits = state is OutfitLoaded
          ? (state as OutfitLoaded).outfits
          : <OutfitModel>[];

      final updatedOutfits = currentOutfits.map((o) {
        return o.id == updatedOutfit.id ? updatedOutfit : o;
      }).toList();

      emit(OutfitLoaded(updatedOutfits));
      return true;
    } catch (e) {
      emit(OutfitError(e.toString()));
      return false;
    }
  }

  // Delete outfit
  Future<bool> deleteOutfit(String outfitId) async {
    try {
      emit(const OutfitLoading());

      await _firestore
          .collection(AppConstants.outfitsCollection)
          .doc(outfitId)
          .delete();

      final currentOutfits = state is OutfitLoaded
          ? (state as OutfitLoaded).outfits
          : <OutfitModel>[];

      final updatedOutfits = currentOutfits.where((o) => o.id != outfitId).toList();

      emit(OutfitLoaded(updatedOutfits));
      return true;
    } catch (e) {
      emit(OutfitError(e.toString()));
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
      final currentOutfits = state is OutfitLoaded
          ? (state as OutfitLoaded).outfits
          : <OutfitModel>[];

      final outfit = currentOutfits.firstWhere((o) => o.id == outfitId);

      final items = outfit.clothingItemIds
          .map((id) => wardrobe.firstWhere((item) => item.id == id))
          .toList();

      return outfit.copyWith(items: items);
    } catch (e) {
      emit(OutfitError(e.toString()));
      return null;
    }
  }

  // Clear error
  void clearError() {
    if (state is OutfitError) {
      emit(const OutfitInitial());
    }
  }
}
