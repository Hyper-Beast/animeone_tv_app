import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 胶囊样式选择器 - 类似 iOS 的 Segmented Control
class TvCapsuleSelector extends StatelessWidget {
  final List<String> labels;
  final List<int> counts;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onMoveLeft;

  const TvCapsuleSelector({
    super.key,
    required this.labels,
    required this.counts,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onMoveLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: _CapsuleItem(
              label: labels[index],
              count: counts.isNotEmpty && index < counts.length
                  ? counts[index]
                  : 0,
              isSelected: selectedIndex == index,
              onTap: () => onIndexChanged(index),
              onMoveLeft: (index == 0) ? onMoveLeft : null,
            ),
          );
        }),
      ),
    );
  }
}

class _CapsuleItem extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onMoveLeft;

  const _CapsuleItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.onMoveLeft,
  });

  @override
  State<_CapsuleItem> createState() => _CapsuleItemState();
}

class _CapsuleItemState extends State<_CapsuleItem> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft &&
            widget.onMoveLeft != null) {
          widget.onMoveLeft!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          widget.onTap();
        }
        setState(() {});
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.blueAccent
                : _focusNode.hasFocus
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            // 🔥 焦点时始终显示白边，无论是否选中
            border: _focusNode.hasFocus
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: widget.isSelected || _focusNode.hasFocus
                        ? Colors.white
                        : Colors.white60,
                  ),
                ),
                if (widget.count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isSelected || _focusNode.hasFocus
                            ? Colors.white
                            : Colors.white60,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
