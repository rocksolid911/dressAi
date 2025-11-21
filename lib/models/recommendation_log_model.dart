import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RecommendationContext extends Equatable {
  final String? occasion;
  final String? mood;
  final String? weather;
  final double? temperature;
  final String? userPrompt;

  const RecommendationContext({
    this.occasion,
    this.mood,
    this.weather,
    this.temperature,
    this.userPrompt,
  });

  Map<String, dynamic> toMap() {
    return {
      'occasion': occasion,
      'mood': mood,
      'weather': weather,
      'temperature': temperature,
      'userPrompt': userPrompt,
    };
  }

  factory RecommendationContext.fromMap(Map<String, dynamic> map) {
    return RecommendationContext(
      occasion: map['occasion'],
      mood: map['mood'],
      weather: map['weather'],
      temperature: map['temperature']?.toDouble(),
      userPrompt: map['userPrompt'],
    );
  }

  @override
  List<Object?> get props => [occasion, mood, weather, temperature, userPrompt];
}

class RecommendationLogModel extends Equatable {
  final String id;
  final String userId;
  final RecommendationContext inputContext;
  final List<String> suggestedOutfitIds;
  final String? aiExplanation;
  final bool? liked;
  final DateTime createdAt;

  const RecommendationLogModel({
    required this.id,
    required this.userId,
    required this.inputContext,
    required this.suggestedOutfitIds,
    this.aiExplanation,
    this.liked,
    required this.createdAt,
  });

  // From Firestore
  factory RecommendationLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecommendationLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      inputContext: RecommendationContext.fromMap(
        Map<String, dynamic>.from(data['inputContext'] ?? {}),
      ),
      suggestedOutfitIds: List<String>.from(data['suggestedOutfitIds'] ?? []),
      aiExplanation: data['aiExplanation'],
      liked: data['liked'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'inputContext': inputContext.toMap(),
      'suggestedOutfitIds': suggestedOutfitIds,
      'aiExplanation': aiExplanation,
      'liked': liked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with
  RecommendationLogModel copyWith({
    String? id,
    String? userId,
    RecommendationContext? inputContext,
    List<String>? suggestedOutfitIds,
    String? aiExplanation,
    bool? liked,
    DateTime? createdAt,
  }) {
    return RecommendationLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      inputContext: inputContext ?? this.inputContext,
      suggestedOutfitIds: suggestedOutfitIds ?? this.suggestedOutfitIds,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      liked: liked ?? this.liked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        inputContext,
        suggestedOutfitIds,
        aiExplanation,
        liked,
        createdAt,
      ];
}
