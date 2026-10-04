import 'package:flutter/material.dart';
import 'settings.dart';
import '../../platform/launcher_icon_controller.dart';
import '../launcher_icons/launcher_icon_picker.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onChangeEnd,
    this.launcherIcons,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onChangeEnd;
  final LauncherIconController? launcherIcons;

  Widget _slider(
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
            style: const TextStyle(
              color: Color(0xFFCEB9FF),
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

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AnimationKind>(
            segments: const [
              ButtonSegment(
                value: AnimationKind.spiral,
                label: Text('螺旋'),
                icon: Icon(Icons.blur_on),
              ),
              ButtonSegment(
                value: AnimationKind.hearts,
                label: Text('爱心'),
                icon: Icon(Icons.favorite_outline),
              ),
            ],
            selected: {settings.kind},
            showSelectedIcon: false,
            onSelectionChanged: (values) =>
                _change(settings.copyWith(kind: values.single)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '配色',
          style: TextStyle(color: Color(0xFFABA6BC), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in [(0, '黑白'), (1, '紫黑'), (2, '粉白')])
              ActionChip(
                label: Text(entry.$2),
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
        const SizedBox(height: 22),
        _slider(
          '播放速度',
          settings.speed,
          .1,
          2,
          (value) => onChanged(settings.copyWith(speed: value)),
          display: '${settings.speed.toStringAsFixed(1)}×',
        ),
        if (settings.kind == AnimationKind.spiral) ...[
          _slider(
            '条纹数量',
            settings.stripes.toDouble(),
            2,
            8,
            (value) => onChanged(settings.copyWith(stripes: value.round())),
            display: '${settings.stripes}',
            divisions: 6,
          ),
          _slider(
            '螺旋疏密',
            settings.density,
            1,
            5,
            (value) => onChanged(settings.copyWith(density: value)),
          ),
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
          if (settings.showCenterHeart)
            _slider(
              '爱心大小',
              settings.centerHeartFraction,
              .05,
              .2,
              (value) =>
                  onChanged(settings.copyWith(centerHeartFraction: value)),
              display: '${(settings.centerHeartFraction * 100).round()}%',
            ),
        ] else
          _slider(
            '扩散间隔',
            settings.heartIntervalSeconds,
            .4,
            2,
            (value) =>
                onChanged(settings.copyWith(heartIntervalSeconds: value)),
            display: '${settings.heartIntervalSeconds.toStringAsFixed(1)} 秒',
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
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
              (
                '爱心色',
                settings.heartArgb,
                (int v) => settings.copyWith(heartArgb: v),
              ),
            ])
              OutlinedButton.icon(
                icon: Icon(Icons.circle, color: Color(entry.$2), size: 16),
                label: Text(entry.$1),
                onPressed: () => _color(
                  context,
                  entry.$1,
                  entry.$2,
                  (value) => onChanged(entry.$3(value)),
                ),
              ),
          ],
        ),
        if (launcherIcons != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          LauncherIconPicker(controller: launcherIcons!),
        ],
      ],
    ),
  );
}
