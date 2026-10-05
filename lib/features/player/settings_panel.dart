import 'package:flutter/material.dart';
import 'settings.dart';

enum SettingsSection { shape, color }

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onChangeEnd,
    this.section = SettingsSection.shape,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onChangeEnd;
  final SettingsSection section;

  Widget _slider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> changed, {
    String? display,
    int? divisions,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            display ?? value.toStringAsFixed(1),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: display,
        onChanged: changed,
        onChangeEnd: (_) => onChangeEnd(),
      ),
    ],
  );

  void _change(AppSettings next) {
    onChanged(next);
    onChangeEnd();
  }

  Future<void> _color(
    BuildContext context,
    String label,
    int initial,
    ValueChanged<int> changed,
  ) async {
    var value = initial;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final entry in [('红', 16), ('绿', 8), ('蓝', 0)])
                    _slider(
                      context,
                      entry.$1,
                      ((value >> entry.$2) & 255).toDouble(),
                      0,
                      255,
                      (number) {
                        setState(
                          () => value =
                              0xFF000000 |
                              ((value & ~(255 << entry.$2)) |
                                  (number.round() << entry.$2)),
                        );
                        changed(value);
                      },
                      display: '${(value >> entry.$2) & 255}',
                      divisions: 255,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
    onChangeEnd();
  }

  List<Widget> _shape(BuildContext context) => [
    if (settings.kind == AnimationKind.spiral) ...[
      _slider(
        context,
        '条纹数量',
        settings.stripes.toDouble(),
        2,
        8,
        (value) => onChanged(settings.copyWith(stripes: value.round())),
        display: '${settings.stripes}',
        divisions: 6,
      ),
      const SizedBox(height: 12),
      _slider(
        context,
        '螺旋疏密',
        settings.density,
        1,
        5,
        (value) => onChanged(settings.copyWith(density: value)),
      ),
      const Divider(height: 24),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('顺时针'),
        value: settings.clockwise,
        onChanged: (value) => _change(settings.copyWith(clockwise: value)),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('中心爱心'),
        value: settings.showCenterHeart,
        onChanged: (value) =>
            _change(settings.copyWith(showCenterHeart: value)),
      ),
      if (settings.showCenterHeart) ...[
        const SizedBox(height: 16),
        _slider(
          context,
          '爱心大小',
          settings.centerHeartFraction,
          .05,
          .2,
          (value) => onChanged(settings.copyWith(centerHeartFraction: value)),
          display: '${(settings.centerHeartFraction * 100).round()}%',
        ),
      ],
    ] else
      _slider(
        context,
        '扩散间隔',
        settings.heartIntervalSeconds,
        .4,
        2,
        (value) => onChanged(settings.copyWith(heartIntervalSeconds: value)),
        display: '${settings.heartIntervalSeconds.toStringAsFixed(1)} 秒',
      ),
  ];

  List<Widget> _colors(BuildContext context) => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in [(0, '黑白'), (1, '紫黑'), (2, '粉白')])
          ActionChip(
            label: Text(entry.$2),
            side: BorderSide.none,
            avatar: CircleAvatar(
              radius: 7,
              backgroundColor: Color(
                settings.preset(entry.$1).kind == AnimationKind.hearts
                    ? settings.preset(entry.$1).heartArgb
                    : settings.preset(entry.$1).foregroundArgb,
              ),
            ),
            onPressed: () => _change(settings.preset(entry.$1)),
          ),
      ],
    ),
    const SizedBox(height: 20),
    for (final entry in [
      (
        '背景',
        settings.backgroundArgb,
        (int v) => settings.copyWith(backgroundArgb: v),
      ),
      (
        '主色',
        settings.foregroundArgb,
        (int v) => settings.copyWith(foregroundArgb: v),
      ),
      ('爱心色', settings.heartArgb, (int v) => settings.copyWith(heartArgb: v)),
    ])
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(entry.$1),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(entry.$2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
        onTap: () => _color(
          context,
          entry.$1,
          entry.$2,
          (value) => onChanged(entry.$3(value)),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: section == SettingsSection.shape
          ? _shape(context)
          : _colors(context),
    ),
  );
}
