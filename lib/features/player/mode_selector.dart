import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'settings.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key, required this.value, required this.onChanged});
  final AnimationKind value;
  final ValueChanged<AnimationKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<AnimationKind>(
        groupValue: value,
        backgroundColor: colors.surfaceContainerLowest,
        thumbColor: colors.surfaceContainerHighest,
        padding: const EdgeInsets.all(3),
        children: {
          for (final kind in AnimationKind.values)
            kind: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(
                kind == AnimationKind.spiral ? '螺旋' : '爱心',
                style: TextStyle(
                  color: value == kind
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
        },
        onValueChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
