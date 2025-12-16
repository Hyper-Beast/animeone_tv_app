import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvKeyboardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onMoveLeft;
  const TvKeyboardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onMoveLeft,
  });
  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              onMoveLeft != null) {
            onMoveLeft!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: focused ? Colors.blueAccent : Colors.white24,
                borderRadius: BorderRadius.circular(6),
                border: focused
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
