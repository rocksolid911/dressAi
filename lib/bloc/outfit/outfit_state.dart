import 'package:equatable/equatable.dart';
import '../../models/outfit_model.dart';

abstract class OutfitState extends Equatable {
  const OutfitState();

  @override
  List<Object?> get props => [];
}

class OutfitInitial extends OutfitState {
  const OutfitInitial();
}

class OutfitLoading extends OutfitState {
  const OutfitLoading();
}

class OutfitLoaded extends OutfitState {
  final List<OutfitModel> outfits;

  const OutfitLoaded(this.outfits);

  @override
  List<Object?> get props => [outfits];

  // Helper methods
  List<OutfitModel> get favoriteOutfits {
    return outfits.where((outfit) => outfit.isFavorite).toList();
  }

  List<OutfitModel> getOutfitsByOccasion(String occasion) {
    return outfits.where((outfit) => outfit.occasion == occasion).toList();
  }

  List<OutfitModel> get scheduledOutfits {
    return outfits.where((outfit) => outfit.scheduledDate != null).toList();
  }

  List<OutfitModel> getOutfitsForDate(DateTime date) {
    return outfits.where((outfit) {
      if (outfit.scheduledDate == null) return false;
      return outfit.scheduledDate!.year == date.year &&
          outfit.scheduledDate!.month == date.month &&
          outfit.scheduledDate!.day == date.day;
    }).toList();
  }

  List<OutfitModel> getUpcomingOutfits() {
    final now = DateTime.now();
    return outfits
        .where((outfit) =>
            outfit.scheduledDate != null &&
            outfit.scheduledDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));
  }

  List<OutfitModel> searchOutfits(String query) {
    final lowercaseQuery = query.toLowerCase();
    return outfits.where((outfit) {
      return outfit.name.toLowerCase().contains(lowercaseQuery) ||
          (outfit.occasion?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          outfit.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}

class OutfitError extends OutfitState {
  final String message;

  const OutfitError(this.message);

  @override
  List<Object?> get props => [message];
}
