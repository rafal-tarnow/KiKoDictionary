// ================= ZMIANA: Dodano import profilu =================
import '../../../user/data/models/user_profile_model.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String role;

  final UserProfile? profile;
  final String accountSubscription; 

  // Wygodny getter (Clean Code), żeby w UI pisać `if (user.isPro)`
  bool get isPro => accountSubscription.toUpperCase() == 'PRO';

  User({
    required this.id, 
    required this.username, 
    required this.email, 
    required this.role,
    this.profile,
    required this.accountSubscription,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['account_role'],
      accountSubscription: json['account_subscription'] ?? 'FREE',
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile']) 
          : null,
    );
  }
}