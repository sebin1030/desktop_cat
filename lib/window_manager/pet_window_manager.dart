import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../settings/app_settings.dart';

class PetWindowManager {
  PetWindowManager(this.settings);

  final AppSettings settings;

  Future<void> initialize() async {
    final size = Size(settings.spriteSize + 48, settings.spriteSize + 48);
    await windowManager.setSize(size);
    await moveTo(await _initialPosition(size));
  }

  Future<Offset> position() async {
    return windowManager.getPosition();
  }

  Future<void> moveTo(Offset offset) async {
    final area = await safeArea();
    final bounded = Offset(
      offset.dx.clamp(area.left, area.right - settings.spriteSize).toDouble(),
      offset.dy.clamp(area.top, area.bottom - settings.spriteSize).toDouble(),
    );
    await windowManager.setPosition(bounded);
  }

  Future<Rect> safeArea() async {
    final displays = await screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      return const Rect.fromLTWH(0, 0, 1280, 720);
    }

    var left = displays.first.visiblePosition?.dx ?? 0;
    var top = displays.first.visiblePosition?.dy ?? 0;
    final firstSize = displays.first.visibleSize ?? displays.first.size;
    var right = left + firstSize.width;
    var bottom = top + firstSize.height;

    for (final display in displays.skip(1)) {
      final position = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;
      left = left < position.dx ? left : position.dx;
      top = top < position.dy ? top : position.dy;
      right = right > position.dx + size.width ? right : position.dx + size.width;
      bottom = bottom > position.dy + size.height ? bottom : position.dy + size.height;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Future<Offset> _initialPosition(Size windowSize) async {
    final area = await safeArea();
    return Offset(
      area.right - windowSize.width - 32,
      area.bottom - windowSize.height - 32,
    );
  }
}
