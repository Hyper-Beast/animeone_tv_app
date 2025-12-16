import 'package:flutter/material.dart';

// 🔥 星期按钮：增加高度和字体，使其更大
class TvWeekButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFocus;
  const TvWeekButton({
    super.key,
    required this.label,
    this.count = 0,
    required this.isSelected,
    required this.onTap,
    required this.onFocus,
  });
  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (f) => f ? onFocus() : null,
    child: Builder(
      builder: (ctx) {
        final f = Focus.of(ctx).hasFocus;
        Color bg = isSelected ? Colors.white : Colors.white10;
        Color fg = isSelected ? Colors.black : Colors.white70;
        if (f) {
          bg = Colors.blueAccent;
          fg = Colors.white;
        }
        return Container(
          // 🔥 修改：增加高度从45到55，使其与"查看"按钮对齐
          height: 55,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: f ? Border.all(color: Colors.white, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                // 🔥 修改：稍微调大字体
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: f || isSelected
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(fontSize: 12, color: fg),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
