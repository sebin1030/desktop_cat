import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../idle_detector/idle_detector.dart';
import '../settings/app_settings.dart';
import '../window_manager/pet_window_manager.dart';
import 'pet_state.dart';

class PetStateController extends ChangeNotifier {
  PetStateController({
    required this.settings,
    required this.idleDetector,
    required this.windowManager,
  });

  final AppSettings settings;
  final IdleDetector idleDetector;
  final PetWindowManager windowManager;
  final _random = Random();

  Timer? _ticker;
  DateTime _lastTick = DateTime.now();
  DateTime _pauseUntil = DateTime.now();
  PetPose _pausePose = PetPose.sit;
  Offset? _destination;
  int _frame = 0;
  double _frameElapsedMs = 0;
  bool _tickInProgress = false;

  static const _walkFrameDurationMs = 110.0;
  static const _poseFrameDurationMs = 400.0;

  PetPose pose = PetPose.sleep;
  bool facingLeft = false;
  double bobOffset = 0;

  int get frame => _frame;

  void start() {
    idleDetector.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void pauseWalkingNearCurrentPosition() {
    _destination = null;
    _pauseUntil = DateTime.now().add(const Duration(milliseconds: 800));
    pose = PetPose.sleep;
    _frame = 0;
    _frameElapsedMs = 0;
    notifyListeners();
  }

  Future<void> _tick() async {
    // Position lookup is asynchronous. Do not let a slow lookup overlap the
    // next tick, otherwise old and new window positions race and movement
    // appears to stutter.
    if (_tickInProgress) {
      return;
    }
    _tickInProgress = true;

    try {
      final now = DateTime.now();
      final elapsed = now.difference(_lastTick);
      _lastTick = now;
      final idleState = await idleDetector.currentState();

      switch (idleState) {
        case UserIdleState.active:
          _destination = null;
          _setPose(PetPose.sleep);
        case UserIdleState.shortIdle:
          _destination = null;
          _setPose(PetPose.stretch);
        case UserIdleState.longIdle:
          await _walk(elapsed, now);
      }

      _advanceFrame(elapsed);
      notifyListeners();
    } finally {
      _tickInProgress = false;
    }
  }

  Future<void> _walk(Duration elapsed, DateTime now) async {
    if (now.isBefore(_pauseUntil)) {
      _setPose(_pausePose);
      return;
    }

    _setPose(PetPose.walk);
    final current = await windowManager.position();
    final destination = _destination ?? await _newDestination();
    _destination = destination;

    final delta = destination - current;
    final distance = delta.distance;
    if (distance < 8) {
      _destination = null;
      final pauseRange =
          settings.pauseMax.inMilliseconds - settings.pauseMin.inMilliseconds;
      _pauseUntil = now.add(settings.pauseMin +
          Duration(milliseconds: _random.nextInt(max(1, pauseRange))));
      _pausePose = _random.nextBool() ? PetPose.sit : PetPose.yawn;
      _setPose(_pausePose);
      return;
    }

    final step = settings.walkSpeed * elapsed.inMilliseconds / 1000;
    final next = current + delta / distance * min(step, distance);
    facingLeft = delta.dx < 0;
    // A small vertical body motion follows the six-frame gait instead of an
    // unrelated timer phase, so the feet and body read as one animation.
    bobOffset = [0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5][_frame % 8];
    await windowManager.moveTo(next);
  }

  Future<Offset> _newDestination() async {
    final area = await windowManager.safeArea();
    final size = settings.spriteSize;
    final left = area.left;
    final top = area.top;
    final right = max(left, area.right - size);
    final bottom = max(top, area.bottom - size);
    return Offset(
      left + _random.nextDouble() * max(1, right - left),
      top + _random.nextDouble() * max(1, bottom - top),
    );
  }

  void _setPose(PetPose next) {
    if (pose == next) {
      return;
    }
    pose = next;
    _frame = 0;
    _frameElapsedMs = 0;
    bobOffset = 0;
  }

  void _advanceFrame(Duration elapsed) {
    _frameElapsedMs += elapsed.inMicroseconds / 1000.0;
    final frameDuration = pose == PetPose.walk
        ? _walkFrameDurationMs
        : _poseFrameDurationMs;
    final frames = pose.frames(facingLeft: facingLeft);
    while (_frameElapsedMs >= frameDuration) {
      _frameElapsedMs -= frameDuration;
      _frame = (_frame + 1) % frames.length;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    idleDetector.dispose();
    super.dispose();
  }
}
