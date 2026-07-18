import 'package:flutter/material.dart';

import '../state_manager/pet_state.dart';

class CatSprite extends StatelessWidget {
  const CatSprite({
    super.key,
    required this.character,
    required this.pose,
    required this.frame,
    required this.facingLeft,
    required this.bobOffset,
    required this.size,
  });

  final String character;
  final PetPose pose;
  final int frame;
  final bool facingLeft;
  final double bobOffset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final frames = pose.frames(facingLeft: facingLeft);
    final name = frames[frame % frames.length];
    final path = 'assets/characters/$character/sprites/$name.png';

    return Transform.translate(
      offset: Offset(0, bobOffset),
      child: Image.asset(
        path,
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _MissingSprite(name: name, size: size),
      ),
    );
  }
}

class _MissingSprite extends StatelessWidget {
  const _MissingSprite({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CF),
        border: Border.all(color: const Color(0xFF4A3A2A), width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4A3A2A),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
