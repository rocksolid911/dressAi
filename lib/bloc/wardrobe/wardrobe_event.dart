import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/clothing_item_model.dart';

abstract class WardrobeEvent extends Equatable {
  const WardrobeEvent();

  @override
  List<Object?> get props => [];
}

class LoadWardrobeItems extends WardrobeEvent {
  final String userId;

  const LoadWardrobeItems(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddClothingItem extends WardrobeEvent {
  final String userId;
  final File imageFile;
  final String category;
  final String subcategory;
  final String color;
  final String pattern;
  final String? fabric;
  final String season;
  final List<String> tags;
  final List<String> occasionTags;
  final String? brand;
  final double? price;

  const AddClothingItem({
    required this.userId,
    required this.imageFile,
    required this.category,
    required this.subcategory,
    required this.color,
    this.pattern = 'Solid',
    this.fabric,
    this.season = 'All Season',
    this.tags = const [],
    this.occasionTags = const [],
    this.brand,
    this.price,
  });

  @override
  List<Object?> get props => [
        userId,
        imageFile,
        category,
        subcategory,
        color,
        pattern,
        fabric,
        season,
        tags,
        occasionTags,
        brand,
        price,
      ];
}

class AnalyzeImage extends WardrobeEvent {
  final File imageFile;

  const AnalyzeImage(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class UpdateClothingItem extends WardrobeEvent {
  final ClothingItemModel item;

  const UpdateClothingItem(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteClothingItem extends WardrobeEvent {
  final ClothingItemModel item;

  const DeleteClothingItem(this.item);

  @override
  List<Object?> get props => [item];
}

class ToggleFavorite extends WardrobeEvent {
  final ClothingItemModel item;

  const ToggleFavorite(this.item);

  @override
  List<Object?> get props => [item];
}

class MarkAsWorn extends WardrobeEvent {
  final ClothingItemModel item;

  const MarkAsWorn(this.item);

  @override
  List<Object?> get props => [item];
}

class ClearWardrobeError extends WardrobeEvent {
  const ClearWardrobeError();
}
