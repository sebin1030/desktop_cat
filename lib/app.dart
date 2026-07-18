import 'package:flutter/material.dart';

import 'animation/cat_sprite.dart';
import 'drag_controller/drag_controller.dart';
import 'idle_detector/idle_detector.dart';
import 'settings/app_settings.dart';
import 'sleep_preventer/sleep_preventer.dart';
import 'state_manager/pet_state_controller.dart';
import 'window_manager/pet_window_manager.dart';

class DesktopCatApp extends StatefulWidget {
  const DesktopCatApp({
    super.key,
    required this.settings,
    required this.sleepPreventer,
    required this.petWindowManager,
  });

  final AppSettings settings;
  final SleepPreventer sleepPreventer;
  final PetWindowManager petWindowManager;

  @override
  State<DesktopCatApp> createState() => _DesktopCatAppState();
}

class _DesktopCatAppState extends State<DesktopCatApp> {
  late final IdleDetector _idleDetector;
  late final PetStateController _controller;
  late final DragController _dragController;

  @override
  void initState() {
    super.initState();
    _idleDetector = IdleDetector(
      stretchAfter: widget.settings.idleStretchAfter,
      walkAfter: widget.settings.idleWalkAfter,
    );
    _controller = PetStateController(
      settings: widget.settings,
      idleDetector: _idleDetector,
      windowManager: widget.petWindowManager,
    )..start();
    _dragController = DragController(
      windowManager: widget.petWindowManager,
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _idleDetector.dispose();
    widget.sleepPreventer.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _dragController.start,
          onPanUpdate: _dragController.update,
          onPanEnd: _dragController.end,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Center(
                child: CatSprite(
                  character: widget.settings.character,
                  pose: _controller.pose,
                  frame: _controller.frame,
                  facingLeft: _controller.facingLeft,
                  bobOffset: _controller.bobOffset,
                  size: widget.settings.spriteSize,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
