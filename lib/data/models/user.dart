import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 5)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? profilePictureUrl;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastLoginAt;

  @HiveField(6)
  Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profilePictureUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastLoginAt = lastLoginAt ?? DateTime.now(),
       preferences = preferences ?? {};

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  static User fromFirestore(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastLoginAt: DateTime.parse(data['lastLoginAt'] as String),
      preferences: Map<String, dynamic>.from(data['preferences'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name)';
  }
}