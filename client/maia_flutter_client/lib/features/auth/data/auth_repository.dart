import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ZMIANA: Importujemy provider dedykowany dla auth
import 'auth_dio_provider.dart'; 
import 'models/auth_token.dart';

final authRepositoryProvider = Provider((ref) {
  // ZMIANA: Watchujemy authDioProvider zamiast głównego dioProvider
  final dio = ref.watch(authDioProvider); 
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // Logowanie: x-www-form-urlencoded
  Future<AuthToken> login({required String username, required String password}) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'username': username,
          'password': password,
          'grant_type': 'password', // Wymagane przez OAuth2PasswordBearer
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType, // WAŻNE!
        ),
      );
      return AuthToken.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Rejestracja: application/json
  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String captchaId,
    required String captchaAnswer,
  }) async {
    try {
      await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
          'captcha_id': captchaId,
          'captcha_answer': captchaAnswer,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Wylogowanie
  Future<void> logout(String refreshToken) async {
      // API wymaga wysłania refresh tokena przy wylogowaniu
      await _dio.post('/api/v1/auth/logout', data: {'refresh_token': refreshToken});
  }
}