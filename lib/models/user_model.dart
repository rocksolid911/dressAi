import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? city;
  final String? country;
  final String genderPreference;
  final List<String> stylePreferences;
  final Map<String, String> sizes; // {'tops': 'M', 'bottoms': '32', 'shoes': '9'}
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.city,
    this.country,
    this.genderPreference = 'All Styles',
    this.stylePreferences = const [],
    this.sizes = const {},
    required this.createdAt,
    required this.updatedAt,
    this.onboardingCompleted = false,
  });

  // From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      city: data['city'],
      country: data['country'],
      genderPreference: data['genderPreference'] ?? 'All Styles',
      stylePreferences: List<String>.from(data['stylePreferences'] ?? []),
      sizes: Map<String, String>.from(data['sizes'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'city': city,
      'country': country,
      'genderPreference': genderPreference,
      'stylePreferences': stylePreferences,
      'sizes': sizes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'onboardingCompleted': onboardingCompleted,
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? city,
    String? country,
    String? genderPreference,
    List<String>? stylePreferences,
    Map<String, String>? sizes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      city: city ?? this.city,
      country: country ?? this.country,
      genderPreference: genderPreference ?? this.genderPreference,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      sizes: sizes ?? this.sizes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        city,
        country,
        genderPreference,
        stylePreferences,
        sizes,
        createdAt,
        updatedAt,
        onboardingCompleted,
      ];
}
