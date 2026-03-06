// ================= ZMIANA: Dodano import profilu =================
import '../../../user/data/models/user_profile_model.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String role;
  // ================= ZMIANA: Nowe pole =================
  final UserProfile? profile; 

  User({
    required this.id, 
    required this.username, 
    required this.email, 
    required this.role,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['account_role'],
      // ================= ZMIANA: Parsowanie zagnieżdżonego obiektu =================
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile']) 
          : null,
    );
  }
}