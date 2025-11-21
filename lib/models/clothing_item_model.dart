import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClothingItemModel extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
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
  final bool isFavorite;
  final DateTime? lastWornAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClothingItemModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
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
    this.isFavorite = false,
    this.lastWornAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore
  factory ClothingItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClothingItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      color: data['color'] ?? '',
      pattern: data['pattern'] ?? 'Solid',
      fabric: data['fabric'],
      season: data['season'] ?? 'All Season',
      tags: List<String>.from(data['tags'] ?? []),
      occasionTags: List<String>.from(data['occasionTags'] ?? []),
      brand: data['brand'],
      price: data['price']?.toDouble(),
      isFavorite: data['isFavorite'] ?? false,
      lastWornAt: data['lastWornAt'] != null
          ? (data['lastWornAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'category': category,
      'subcategory': subcategory,
      'color': color,
      'pattern': pattern,
      'fabric': fabric,
      'season': season,
      'tags': tags,
      'occasionTags': occasionTags,
      'brand': brand,
      'price': price,
      'isFavorite': isFavorite,
      'lastWornAt': lastWornAt != null ? Timestamp.fromDate(lastWornAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with
  ClothingItemModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? category,
    String? subcategory,
    String? color,
    String? pattern,
    String? fabric,
    String? season,
    List<String>? tags,
    List<String>? occasionTags,
    String? brand,
    double? price,
    bool? isFavorite,
    DateTime? lastWornAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClothingItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      color: color ?? this.color,
      pattern: pattern ?? this.pattern,
      fabric: fabric ?? this.fabric,
      season: season ?? this.season,
      tags: tags ?? this.tags,
      occasionTags: occasionTags ?? this.occasionTags,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
      lastWornAt: lastWornAt ?? this.lastWornAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        imageUrl,
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
        isFavorite,
        lastWornAt,
        createdAt,
        updatedAt,
      ];
}
