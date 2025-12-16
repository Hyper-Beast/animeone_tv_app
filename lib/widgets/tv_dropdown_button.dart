import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvDropdownButton<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<T> onChanged;
  final VoidCallback? onMoveLeft;
  const TvDropdownButton({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
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
          _showDialog(context);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    child: Builder(
      builder: (ctx) {
        final f = Focus.of(ctx).hasFocus;
        return InkWell(
          onTap: () => _showDialog(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(6),
              border: f
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (c, i) => TvDialogOption(
              label: itemLabelBuilder(items[i]),
              onTap: () {
                onChanged(items[i]);
                Navigator.pop(c);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class TvDialogOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const TvDialogOption({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Focus(
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
        return InkWell(
          onTap: onTap,
          child: Container(
            color: f ? Colors.blueAccent : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: f ? Colors.white : Colors.white70,
              ),
            ),
          ),
        );
      },
    ),
  );
}
