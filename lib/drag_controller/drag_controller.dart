import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../state_manager/pet_state_controller.dart';
import '../window_manager/pet_window_manager.dart';

class DragController {
  DragController({
    required this.windowManager,
    required this.controller,
  });

  final PetWindowManager windowManager;
  final PetStateController controller;

  Offset? _windowStart;
  Offset? _globalStart;

  Future<void> start(DragStartDetails details) async {
    _windowStart = await windowManager.position();
    _globalStart = details.globalPosition;
  }

  Future<void> update(DragUpdateDetails details) async {
    final windowStart = _windowStart;
    final globalStart = _globalStart;
    if (windowStart == null || globalStart == null) {
      return;
    }
    await windowManager.moveTo(windowStart + details.globalPosition - globalStart);
  }

  void end(DragEndDetails details) {
    _windowStart = null;
    _globalStart = null;
    controller.pauseWalkingNearCurrentPosition();
  }
}
