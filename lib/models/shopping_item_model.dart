import 'package:equatable/equatable.dart';

class ShoppingItemModel extends Equatable {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double price;
  final String? brand;
  final String affiliateUrl;
  final String provider; // Amazon, Myntra, etc.
  final List<String> colors;
  final double? rating;
  final String? description;

  const ShoppingItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.price,
    this.brand,
    required this.affiliateUrl,
    this.provider = 'Generic',
    this.colors = const [],
    this.rating,
    this.description,
  });

  // From JSON (for API responses)
  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] as num).toDouble(),
      brand: json['brand'],
      affiliateUrl: json['affiliateUrl'] ?? '',
      provider: json['provider'] ?? 'Generic',
      colors: List<String>.from(json['colors'] ?? []),
      rating: json['rating']?.toDouble(),
      description: json['description'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'price': price,
      'brand': brand,
      'affiliateUrl': affiliateUrl,
      'provider': provider,
      'colors': colors,
      'rating': rating,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        imageUrl,
        price,
        brand,
        affiliateUrl,
        provider,
        colors,
        rating,
        description,
      ];
}
