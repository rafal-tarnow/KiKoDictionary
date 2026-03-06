import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_dio_provider.dart'; // Używamy tego samego dio co Auth (z tokenem)
import '../../auth/data/models/user_model.dart';
import 'models/user_profile_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(authDioProvider);
  return UserRepository(dio);
});

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  // Pobranie własnych danych (odpala się po logowaniu)
  Future<User> getUserMe() async {
    try {
      final response = await _dio.get('/api/v1/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Zaktualizowanie profilu (PATCH)
  Future<UserProfile> updateProfile({required String nativeLanguage}) async {
    try {
      final response = await _dio.patch(
        '/api/v1/users/me/profile',
        data: {
          'native_language': nativeLanguage,
          // ui_theme narazie nie wysyłamy, backend je pominie
        },
      );
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}