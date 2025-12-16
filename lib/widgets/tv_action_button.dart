import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onMoveLeft;
  const TvActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.onMoveLeft,
  });
  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (n, e) {
      if (e is KeyDownEvent) {
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft &&
            onMoveLeft != null) {
          onMoveLeft!();
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.enter ||
            e.logicalKey == LogicalKeyboardKey.select) {
          onTap();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    child: Builder(
      builder: (c) {
        final f = Focus.of(c).hasFocus;
        return InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            decoration: BoxDecoration(
              color: f ? Colors.white : color,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: f ? Colors.black : Colors.white,
              ),
            ),
          ),
        );
      },
    ),
  );
}
