import 'dart:async';

import 'package:flutter/services.dart';

enum UserIdleState {
  active,
  shortIdle,
  longIdle,
}

class IdleDetector {
  IdleDetector({
    required this.stretchAfter,
    required this.walkAfter,
  });

  static const _channel = MethodChannel('desktop_cat/idle_detector');

  final Duration stretchAfter;
  final Duration walkAfter;
  Timer? _poller;
  Duration _lastIdle = Duration.zero;

  void start() {
    _poller = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    _refresh();
  }

  Future<UserIdleState> currentState() async {
    await _refresh();
    if (_lastIdle >= walkAfter) {
      return UserIdleState.longIdle;
    }
    if (_lastIdle >= stretchAfter) {
      return UserIdleState.shortIdle;
    }
    return UserIdleState.active;
  }

  Future<void> _refresh() async {
    try {
      final seconds = await _channel.invokeMethod<int>('idleSeconds') ?? 0;
      _lastIdle = Duration(seconds: seconds);
    } catch (_) {
      _lastIdle = Duration.zero;
    }
  }

  void dispose() {
    _poller?.cancel();
  }
}
