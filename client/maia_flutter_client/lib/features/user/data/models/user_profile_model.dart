class UserProfile {
  final String nativeLanguage;
  final String uiTheme;

  UserProfile({
    required this.nativeLanguage,
    required this.uiTheme,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nativeLanguage: json['native_language'] as String? ?? 'en',
      uiTheme: json['ui_theme'] as String? ?? 'system',
    );
  }
}