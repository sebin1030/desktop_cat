import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  double opacity = 1;
  double speedMultiplier = 1;
  double sizeMultiplier = 1;

  void setOpacity(double value) {
    opacity = value.clamp(0.25, 1);
    notifyListeners();
  }

  void setSpeedMultiplier(double value) {
    speedMultiplier = value.clamp(0.25, 3);
    notifyListeners();
  }

  void setSizeMultiplier(double value) {
    sizeMultiplier = value.clamp(0.5, 2);
    notifyListeners();
  }
}
