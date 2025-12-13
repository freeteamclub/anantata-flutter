/// Модель користувача Anantata
/// Версія: 1.0
/// Дата: 12.12.2025

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool onboardingCompleted;
  final bool assessmentCompleted;
  final String? currentPlanId;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.onboardingCompleted = false,
    this.assessmentCompleted = false,
    this.currentPlanId,
  });

  /// Створення з JSON (Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      assessmentCompleted: json['assessment_completed'] as bool? ?? false,
      currentPlanId: json['current_plan_id'] as String?,
    );
  }

  /// Конвертація в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'onboarding_completed': onboardingCompleted,
      'assessment_completed': assessmentCompleted,
      'current_plan_id': currentPlanId,
    };
  }

  /// Копіювання з оновленням полів
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? onboardingCompleted,
    bool? assessmentCompleted,
    String? currentPlanId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      assessmentCompleted: assessmentCompleted ?? this.assessmentCompleted,
      currentPlanId: currentPlanId ?? this.currentPlanId,
    );
  }

  /// Перевірка чи профіль заповнений
  bool get isProfileComplete => name != null && name!.isNotEmpty;

  /// Ім'я для відображення
  String get displayName => name ?? email.split('@').first;

  /// Ініціали для аватара
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
