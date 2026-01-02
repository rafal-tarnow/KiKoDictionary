import 'dart:async';
import 'package:flutter/material.dart'; // Potrzebne do ChangeNotifier

// 1. Dodaj "with ChangeNotifier"
class TestBackend with ChangeNotifier {
  final String brickName = 'Brick M0001';
  bool brickStatus = false;
  int bricksCount = 0;
  Timer? _timer;
  Timer? _statusTimer;

  TestBackend(){
    _startTimer();
    _startStatusTimer();
  }

  void _startStatusTimer(){
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      brickStatus = !brickStatus;

      notifyListeners();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      bricksCount++;
      
      // 2. TO JEST KLUCZ! To mówi do UI: "Hej, zmieniłem się, przerysujcie się!"
      notifyListeners(); 
    });
  }
}