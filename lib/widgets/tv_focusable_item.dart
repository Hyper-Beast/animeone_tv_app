import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 🔥 侧边栏图标按钮：使用SVG图标
class TvFocusableItem extends StatelessWidget {
  final String iconPath; // SVG图标路径
  final bool isSelected;
  final FocusNode focusNode;
  final VoidCallback onFocus;
  final VoidCallback onTap;
  const TvFocusableItem({
    super.key,
    required this.iconPath,
    required this.isSelected,
    required this.focusNode,
    required this.onFocus,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focusNode,
    onFocusChange: (f) => f ? onFocus() : null,
    onKeyEvent: (n, e) {
      if (e is KeyDownEvent &&
          (e.logicalKey == LogicalKeyboardKey.enter ||
              e.logicalKey == LogicalKeyboardKey.select)) {
        onTap();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: Builder(
      builder: (c) {
        final f = Focus.of(c).hasFocus;
        return Container(
          height: 55,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: f
                ? Colors.blueAccent
                : (isSelected ? Colors.white10 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            iconPath,
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              f ? Colors.white : (isSelected ? Colors.white : Colors.grey),
              BlendMode.srcIn,
            ),
          ),
        );
      },
    ),
  );
}
