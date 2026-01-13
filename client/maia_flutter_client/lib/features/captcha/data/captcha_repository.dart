import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './captcha_dio_provider.dart';
import 'models/captcha_model.dart';

// Provider repozytorium
final captchaRepositoryProvider = Provider<CaptchaRepository>((ref) {
  final dio = ref.watch(captchaDioProvider);
  return CaptchaRepository(dio);
});

class CaptchaRepository {
  final Dio _dio;

  CaptchaRepository(this._dio);

  Future<CaptchaModel> generateCaptcha() async {
    try {
      final response = await _dio.get('/api/v1/captcha');
      return CaptchaModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyCaptcha(CaptchaVerifyRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/captcha/verify',
        data: request.toJson(),
      );
      final result = CaptchaVerifyResponse.fromJson(response.data);
      return result.isValid;
    } catch (e) {
      // Jeśli serwer zwróci 422 (błąd walidacji), to technicznie nie jest poprawna captcha
      // Możesz tu obsłużyć to inaczej, ale na razie uznajmy to za false lub rzućmy błąd.
      rethrow; 
    }
  }
}