import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'settings/app_settings.dart';
import 'sleep_preventer/sleep_preventer.dart';
import 'window_manager/pet_window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(220, 220),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      // macOS의 setAsFrameless()는 창을 다시 불투명하게 만들기 때문에
      // 프레임 제거 뒤 제목 표시줄 스타일과 배경색을 재적용해야 한다.
      if (Platform.isMacOS) {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
      }
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
    });
  }

  final settings = await AppSettings.load();
  final sleepPreventer = SleepPreventer();
  await sleepPreventer.enable();
  final petWindowManager = PetWindowManager(settings);
  await petWindowManager.initialize();

  runApp(DesktopCatApp(
    settings: settings,
    sleepPreventer: sleepPreventer,
    petWindowManager: petWindowManager,
  ));
}
