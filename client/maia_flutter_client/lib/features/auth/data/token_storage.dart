import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/auth_token.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

class TokenStorage {
  // POPRAWKA: Usuwamy parametr encryptedSharedPreferences.
  // Dodajemy resetOnError: true -> to "Best Practice" w developmentzie.
  // Jeśli klucze szyfrowania ulegną uszkodzeniu (np. przy reinstalacji apki w devie),
  // magazyn zostanie zresetowany zamiast crashować aplikację.
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true, 
    ),
  );

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  Future<void> saveToken(AuthToken token) async {
    await _storage.write(key: _keyAccess, value: token.accessToken);
    await _storage.write(key: _keyRefresh, value: token.refreshToken);
  }

  Future<AuthToken?> getToken() async {
    // Odczyt może rzucić wyjątek jeśli klucze systemowe się zmienią, 
    // dlatego warto otoczyć to try-catch w produkcyjnym kodzie, 
    // ale resetOnError w opcjach wyżej załatwia większość problemów.
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);
    
    if (access != null && refresh != null) {
      return AuthToken(accessToken: access, refreshToken: refresh);
    }
    return null;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }
}