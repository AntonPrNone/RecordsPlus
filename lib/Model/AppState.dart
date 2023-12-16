import 'dart:io';

import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  File? _backgroundImage;

  AppState({String? backgroundImage}) {
    if (backgroundImage != null) {
      _backgroundImage = File(backgroundImage);
    }
  }

  File? get backgroundImage => _backgroundImage;

  void setBackgroundImage(File? image) {
    _backgroundImage = image;
    notifyListeners();
  }
}
