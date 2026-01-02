import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'test_backend.dart';

// 3. Zmień "Provider" na "ChangeNotifierProvider"
final testBackendProvider = ChangeNotifierProvider<TestBackend>((ref){
  return TestBackend();
});