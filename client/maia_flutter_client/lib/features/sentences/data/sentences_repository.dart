import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import 'sentence_model.dart';
import 'sentence_create_model.dart';
import 'sentence_update_model.dart';

// Prosta klasa (jak struct w C++) do przekazania danych z API do Providera
class SentencesResponse {
  final List<Sentence> sentences;
  final int totalPages;
  final bool isAuthenticated; // NOWE POLE (opcjonalne, ale przydatne)

  SentencesResponse(this.sentences, this.totalPages, {this.isAuthenticated = false});
}

final sentencesRepositoryProvider = Provider<SentencesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SentencesRepository(dio);
});

class SentencesRepository {
  final Dio _dio;

  SentencesRepository(this._dio);

  // Zmieniamy typ zwracany na naszą strukturę SentencesResponse
  Future<SentencesResponse> getSentences({required int page, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        '/api/sentences/me',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      // 1. Odbieramy główny obiekt JSON (Map<String, dynamic>)
      final Map<String, dynamic> json = response.data;

      // 2. Wyciągamy listę z klucza "data"
      final List<dynamic> rawList = json['data'];
      
      // 3. Wyciągamy liczbę stron z klucza "total_pages"
      final int totalPages = json['total_pages'] ?? 1; // domyślnie 1 jakby api nie dało

      // 4. Mapujemy listę
      final sentences = rawList.map((e) => Sentence.fromJson(e)).toList();

      // Zwracamy komplet danych
      return SentencesResponse(sentences, totalPages);

    } catch (e) {
      rethrow;
    }
  }

  // ================= [ZMIANA 1]: Pobieranie Społeczności =================
  Future<SentencesResponse> getCommunitySentences({
    required int page, 
    int perPage = 10,
    String? sourceLang,
    String? targetLang,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      // Dodajemy filtry tylko wtedy, gdy są wybrane
      if (sourceLang != null) queryParams['source_lang'] = sourceLang;
      if (targetLang != null) queryParams['target_lang'] = targetLang;

      final response = await _dio.get(
        '/api/sentences/community',
        queryParameters: queryParams,
      );

      final Map<String, dynamic> json = response.data;
      final List<dynamic> rawList = json['data'];
      final int totalPages = json['total_pages'] ?? 1;
      final bool isAuth = json['is_authenticated'] ?? false;
      
      final sentences = rawList.map((e) => Sentence.fromJson(e)).toList();

      return SentencesResponse(sentences, totalPages, isAuthenticated: isAuth);
    } catch (e) {
      rethrow;
    }
  }
  // =======================================================================

  Future<void> createSentence(SentenceCreate data) async {
    try {
      // Dio automatycznie zserializuje Mapę zwróconą przez data.toJson()
      await _dio.post(
        '/api/sentences/',
        data: data.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSentence(int id) async {
    try {
      // Endpoint: DELETE /api/sentences/{sentence_id}
      await _dio.delete('/api/sentences/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<Sentence> updateSentence({
    required int id,
    required SentenceUpdate data,
  }) async {
    try {
      final response = await _dio.put(
        '/api/sentences/$id',
        data: data.toJson(),
      );
      
      // API zwraca zaktualizowany obiekt Sentence (według dokumnetacji)
      // Od razu go parsujemy i zwracamy wyżej.
      return Sentence.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ================= [ZMIANA 2]: Endpoint Klonowania =================
  Future<Sentence> cloneSentence(int originalId) async {
    try {
      // Puste body, używamy POST
      final response = await _dio.post('/api/sentences/$originalId/clone');
      return Sentence.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  // ===================================================================

}