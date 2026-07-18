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
  int _ticks = 0;

  PetPose pose = PetPose.sleep;
  bool facingLeft = false;
  double bobOffset = 0;

  int get frame => _frame;

  void start() {
    idleDetector.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void pauseWalkingNearCurrentPosition() {
    _destination = null;
    _pauseUntil = DateTime.now().add(const Duration(milliseconds: 800));
    pose = PetPose.sleep;
    _frame = 0;
    notifyListeners();
  }

  Future<void> _tick() async {
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

    _advanceFrame();
    notifyListeners();
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
    bobOffset = sin(_ticks / 2.0) * 4;
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
    bobOffset = 0;
  }

  void _advanceFrame() {
    _ticks++;
    final frameInterval = pose == PetPose.walk ? 1 : 6;
    if (_ticks % frameInterval == 0) {
      _frame = (_frame + 1) % pose.frames().length;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    idleDetector.dispose();
    super.dispose();
  }
}
