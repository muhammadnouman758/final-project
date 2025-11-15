import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatelessWidget {
  final AnimationController animationController;
  final bool isDarkMode;

  const AnimatedBackground({
    super.key,
    required this.animationController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final List<Color> colors = isDarkMode
            ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D), const Color(0xFF131313)]
            : [const Color(0xFFE5F2FF), const Color(0xFFF5F0FF), const Color(0xFFFFEDF5)];

        return Stack(
          children: [
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            ...List.generate(15, (index) {
              final random = Random(index);
              final size = random.nextDouble() * 120 + 50;
              final color = colors[random.nextInt(colors.length)].withOpacity(0.3);
              final startX = random.nextDouble() * MediaQuery.of(context).size.width;
              final startY = random.nextDouble() * MediaQuery.of(context).size.height;
              final animValue = animationController.value;
              final wave = sin(animValue * 2 * pi + index) * 30;

              return Positioned(
                left: startX + wave,
                top: startY + wave,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(size / 2),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}