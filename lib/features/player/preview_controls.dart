import 'package:flutter/material.dart';
import 'mode_selector.dart';
import 'settings.dart';

class PlaybackSpeedControl extends StatelessWidget {
  const PlaybackSpeedControl({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onChangeEnd,
    this.compact = false,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onChangeEnd;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Semantics(
              label: '播放速度',
              excludeSemantics: true,
              child: Text(compact ? '速度' : '播放速度'),
            ),
          ),
          Text(
            '${settings.speed.toStringAsFixed(1)}×',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      Slider(
        value: settings.speed,
        min: .1,
        max: 2,
        label: '${settings.speed.toStringAsFixed(1)}×',
        onChanged: (value) => onChanged(settings.copyWith(speed: value)),
        onChangeEnd: (_) => onChangeEnd(),
      ),
    ],
  );
}

class PreviewControls extends StatelessWidget {
  const PreviewControls({
    super.key,
    required this.settings,
    required this.playing,
    required this.onChanged,
    required this.onCommit,
    required this.onPause,
    required this.onStart,
    required this.onAdjust,
    this.compact = false,
  });
  final AppSettings settings;
  final bool playing;
  final bool compact;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onCommit, onPause, onStart, onAdjust;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mode = ModeSelector(
      value: settings.kind,
      onChanged: (kind) {
        onChanged(settings.copyWith(kind: kind));
        onCommit();
      },
    );
    final speed = PlaybackSpeedControl(
      settings: settings,
      onChanged: onChanged,
      onChangeEnd: onCommit,
      compact: compact,
    );
    return Material(
      key: const Key('preview-controls'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(28),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Row(
                children: [
                  SizedBox(
                    width: (MediaQuery.textScalerOf(context).scale(14) * 4 + 20)
                        .clamp(112.0, double.infinity),
                    child: mode,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: speed),
                ],
              )
            else ...[
              mode,
              const SizedBox(height: 16),
              speed,
            ],
            SizedBox(height: compact ? 8 : 6),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: playing ? '暂停' : '继续',
                  onPressed: onPause,
                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('start-fullscreen'),
                    onPressed: onStart,
                    icon: const Icon(Icons.fullscreen_rounded, size: 20),
                    label: const Text('开始全屏'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: compact ? 8 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: '调整',
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
