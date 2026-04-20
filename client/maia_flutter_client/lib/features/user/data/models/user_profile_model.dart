class UserProfile {
  final String nativeLanguage;
  final String uiTheme;
  final bool isOnboardingCompleted;

  UserProfile({
    required this.nativeLanguage,
    required this.uiTheme,
    required this.isOnboardingCompleted,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nativeLanguage: json['native_language'] as String? ?? 'en',
      uiTheme: json['ui_theme'] as String? ?? 'system',
      isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
    );
  }
}