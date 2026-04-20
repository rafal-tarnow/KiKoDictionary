import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_dio_provider.dart'; // Używamy tego samego dio co Auth (z tokenem)
import '../../auth/data/models/user_model.dart';
import 'models/user_profile_model.dart';
import '../domain/exceptions/user_exceptions.dart';

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

Future<UserProfile> updateProfile({
    String? nativeLanguage, 
    bool? isOnboardingCompleted
  }) async {
    try {
      // Budujemy dynamicznie mapę danych
      final data = <String, dynamic>{};
      if (nativeLanguage != null) data['native_language'] = nativeLanguage;
      if (isOnboardingCompleted != null) data['is_onboarding_completed'] = isOnboardingCompleted;

      final response = await _dio.patch(
        '/api/v1/users/me/profile',
        data: data, // Wysyłamy zbudowaną mapę
      );
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUsername({required String newUsername}) async {
    try {
      final response = await _dio.patch(
        '/api/v1/users/me/username',
        data: {'username': newUsername},
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      // Wyłapujemy specyficzny błąd 409 z FastAPI
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map && data['detail'] is Map) {
          final detail = data['detail'];
          // Bezpiecznie parsowanie listy sugestii przysłanej przez serwer
          final suggestions = List<String>.from(detail['suggestions'] ?? []);
          
          throw UsernameConflictException(
            message: "Ta nazwa użytkownika jest już zajęta.",
            suggestions: suggestions,
          );
        }
      }
      rethrow; // Inne błędy (np. brak neta, 422) lecą dalej do ApiErrorHandler
    } catch (e) {
      rethrow;
    }
  }
}