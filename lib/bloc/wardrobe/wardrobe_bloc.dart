import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../models/clothing_item_model.dart';
import '../../services/storage_service.dart';
import '../../services/ai_image_recognition_service.dart';
import '../../core/constants/app_constants.dart';
import 'wardrobe_event.dart';
import 'wardrobe_state.dart';

class WardrobeBloc extends Bloc<WardrobeEvent, WardrobeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final AiImageRecognitionService _aiService = AiImageRecognitionService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  WardrobeBloc() : super(const WardrobeInitial()) {
    on<LoadWardrobeItems>(_onLoadWardrobeItems);
    on<AddClothingItem>(_onAddClothingItem);
    on<AnalyzeImage>(_onAnalyzeImage);
    on<UpdateClothingItem>(_onUpdateClothingItem);
    on<DeleteClothingItem>(_onDeleteClothingItem);
    on<ToggleFavorite>(_onToggleFavorite);
    on<MarkAsWorn>(_onMarkAsWorn);
    on<ClearWardrobeError>(_onClearWardrobeError);
  }

  Future<void> _onLoadWardrobeItems(
    LoadWardrobeItems event,
    Emitter<WardrobeState> emit,
  ) async {
    try {
      emit(const WardrobeLoading());

      final snapshot = await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .where('userId', isEqualTo: event.userId)
          .orderBy('createdAt', descending: true)
          .get();

      final items = snapshot.docs
          .map((doc) => ClothingItemModel.fromFirestore(doc))
          .toList();

      emit(WardrobeLoaded(items));
    } catch (e) {
      emit(WardrobeError(e.toString()));
    }
  }

  Future<void> _onAddClothingItem(
    AddClothingItem event,
    Emitter<WardrobeState> emit,
  ) async {
    try {
      emit(const WardrobeLoading());

      // Upload image
      final imageUrl = await _storageService.uploadClothingImage(
        imageFile: event.imageFile,
        userId: event.userId,
      );

      // Create clothing item
      final item = ClothingItemModel(
        id: '',
        userId: event.userId,
        imageUrl: imageUrl,
        category: event.category,
        subcategory: event.subcategory,
        color: event.color,
        pattern: event.pattern,
        fabric: event.fabric,
        season: event.season,
        tags: event.tags,
        occasionTags: event.occasionTags,
        brand: event.brand,
        price: event.price,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .add(item.toFirestore());

      final savedItem = item.copyWith(id: docRef.id);

      // Get current items
      final currentItems = state is WardrobeLoaded
          ? (state as WardrobeLoaded).items
          : <ClothingItemModel>[];

      final updatedItems = [savedItem, ...currentItems];

      // Log analytics
      await _analytics.logEvent(
        name: AppConstants.eventAddItem,
        parameters: {'category': event.category, 'subcategory': event.subcategory},
      );

      emit(ClothingItemAdded(savedItem, updatedItems));
      emit(WardrobeLoaded(updatedItems));
    } catch (e) {
      emit(WardrobeError(e.toString()));
    }
  }

  Future<void> _onAnalyzeImage(
    AnalyzeImage event,
    Emitter<WardrobeState> emit,
  ) async {
    try {
      final result = await _aiService.analyzeClothingImage(event.imageFile);
      if (result != null) {
        emit(ImageAnalyzed(result));
      } else {
        emit(const WardrobeError('Failed to analyze image'));
      }
    } catch (e) {
      emit(WardrobeError(e.toString()));
    }
  }

  Future<void> _onUpdateClothingItem(
    UpdateClothingItem event,
    Emitter<WardrobeState> emit,
  ) async {
    try {
      emit(const WardrobeLoading());

      final updatedItem = event.item.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .doc(event.item.id)
          .update(updatedItem.toFirestore());

      final currentItems = state is WardrobeLoaded
          ? (state as WardrobeLoaded).items
          : <ClothingItemModel>[];

      final updatedItems = currentItems.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();

      emit(WardrobeLoaded(updatedItems));
    } catch (e) {
      emit(WardrobeError(e.toString()));
    }
  }

  Future<void> _onDeleteClothingItem(
    DeleteClothingItem event,
    Emitter<WardrobeState> emit,
  ) async {
    try {
      emit(const WardrobeLoading());

      // Delete from Firestore
      await _firestore
          .collection(AppConstants.clothingItemsCollection)
          .doc(event.item.id)
          .delete();

      // Delete image from storage
      await _storageService.deleteImage(event.item.imageUrl);

      final currentItems = state is WardrobeLoaded
          ? (state as WardrobeLoaded).items
          : <ClothingItemModel>[];

      final updatedItems = currentItems.where((item) => item.id != event.item.id).toList();

      emit(WardrobeLoaded(updatedItems));
    } catch (e) {
      emit(WardrobeError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<WardrobeState> emit,
  ) async {
    final updatedItem = event.item.copyWith(isFavorite: !event.item.isFavorite);
    add(UpdateClothingItem(updatedItem));
  }

  Future<void> _onMarkAsWorn(
    MarkAsWorn event,
    Emitter<WardrobeState> emit,
  ) async {
    final updatedItem = event.item.copyWith(lastWornAt: DateTime.now());
    add(UpdateClothingItem(updatedItem));
  }

  Future<void> _onClearWardrobeError(
    ClearWardrobeError event,
    Emitter<WardrobeState> emit,
  ) async {
    if (state is WardrobeError) {
      emit(const WardrobeInitial());
    }
  }
}
