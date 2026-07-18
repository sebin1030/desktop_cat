import 'package:flutter/services.dart';

class SleepPreventer {
  static const _channel = MethodChannel('desktop_cat/sleep_preventer');

  bool _enabled = false;

  Future<void> enable() async {
    if (_enabled) {
      return;
    }
    await _channel.invokeMethod<void>('enable');
    _enabled = true;
  }

  Future<void> disable() async {
    if (!_enabled) {
      return;
    }
    await _channel.invokeMethod<void>('disable');
    _enabled = false;
  }
}
