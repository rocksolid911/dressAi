import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'clothing_item_model.dart';

class OutfitModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final List<String> clothingItemIds;
  final List<ClothingItemModel>? items; // Populated when fetched with items
  final List<String> tags;
  final String? occasion;
  final String? description;
  final bool isFavorite;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OutfitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.clothingItemIds,
    this.items,
    this.tags = const [],
    this.occasion,
    this.description,
    this.isFavorite = false,
    this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore
  factory OutfitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OutfitModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      clothingItemIds: List<String>.from(data['clothingItemIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      occasion: data['occasion'],
      description: data['description'],
      isFavorite: data['isFavorite'] ?? false,
      scheduledDate: data['scheduledDate'] != null
          ? (data['scheduledDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'clothingItemIds': clothingItemIds,
      'tags': tags,
      'occasion': occasion,
      'description': description,
      'isFavorite': isFavorite,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with
  OutfitModel copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? clothingItemIds,
    List<ClothingItemModel>? items,
    List<String>? tags,
    String? occasion,
    String? description,
    bool? isFavorite,
    DateTime? scheduledDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      clothingItemIds: clothingItemIds ?? this.clothingItemIds,
      items: items ?? this.items,
      tags: tags ?? this.tags,
      occasion: occasion ?? this.occasion,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        clothingItemIds,
        items,
        tags,
        occasion,
        description,
        isFavorite,
        scheduledDate,
        createdAt,
        updatedAt,
      ];
}
