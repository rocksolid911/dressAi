import 'package:equatable/equatable.dart';
import '../../models/clothing_item_model.dart';
import '../../services/ai_image_recognition_service.dart';

abstract class WardrobeState extends Equatable {
  const WardrobeState();

  @override
  List<Object?> get props => [];
}

class WardrobeInitial extends WardrobeState {
  const WardrobeInitial();
}

class WardrobeLoading extends WardrobeState {
  const WardrobeLoading();
}

class WardrobeLoaded extends WardrobeState {
  final List<ClothingItemModel> items;

  const WardrobeLoaded(this.items);

  @override
  List<Object?> get props => [items];

  // Helper methods
  List<ClothingItemModel> getItemsByCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }

  List<ClothingItemModel> get favoriteItems {
    return items.where((item) => item.isFavorite).toList();
  }

  List<ClothingItemModel> getItemsBySeason(String season) {
    return items.where((item) =>
        item.season == season || item.season == 'All Season').toList();
  }

  List<ClothingItemModel> searchItems(String query) {
    final lowercaseQuery = query.toLowerCase();
    return items.where((item) {
      return item.category.toLowerCase().contains(lowercaseQuery) ||
          item.subcategory.toLowerCase().contains(lowercaseQuery) ||
          item.color.toLowerCase().contains(lowercaseQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
          (item.brand?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  List<ClothingItemModel> filterItems({
    String? category,
    String? color,
    String? season,
    String? occasion,
    bool? isFavorite,
  }) {
    return items.where((item) {
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

  Map<String, dynamic> getStatistics() {
    return {
      'total': items.length,
      'categories': _getCategoryCounts(),
      'mostWornColor': _getMostWornColor(),
      'leastWornItems': _getLeastWornItems(),
      'favorites': favoriteItems.length,
    };
  }

  Map<String, int> _getCategoryCounts() {
    Map<String, int> counts = {};
    for (var item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  String _getMostWornColor() {
    Map<String, int> colorCounts = {};
    for (var item in items) {
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
    final sortedItems = List<ClothingItemModel>.from(items);
    sortedItems.sort((a, b) {
      if (a.lastWornAt == null && b.lastWornAt == null) return 0;
      if (a.lastWornAt == null) return -1;
      if (b.lastWornAt == null) return 1;
      return a.lastWornAt!.compareTo(b.lastWornAt!);
    });
    return sortedItems.take(5).toList();
  }
}

class WardrobeError extends WardrobeState {
  final String message;

  const WardrobeError(this.message);

  @override
  List<Object?> get props => [message];
}

class ImageAnalyzed extends WardrobeState {
  final ClothingAnalysisResult result;

  const ImageAnalyzed(this.result);

  @override
  List<Object?> get props => [result];
}

class ClothingItemAdded extends WardrobeState {
  final ClothingItemModel item;
  final List<ClothingItemModel> items;

  const ClothingItemAdded(this.item, this.items);

  @override
  List<Object?> get props => [item, items];
}
