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
    final play = Tooltip(
      message: playing ? '暂停' : '继续',
      child: FilledButton.icon(
        key: const Key('toggle-preview-playback'),
        onPressed: onPause,
        icon: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 26,
        ),
        label: Text(playing ? '暂停播放' : '开始播放'),
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(compact ? 56 : 76),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 8 : 16,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
    return Material(
      key: const Key('preview-controls'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(28),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 18),
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
                  const SizedBox(width: 12),
                  Expanded(child: play),
                ],
              )
            else
              mode,
            if (!compact) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAdjust,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  minimumSize: const Size.fromHeight(44),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${settings.speed.toStringAsFixed(1)}×'
                        '${settings.kind == AnimationKind.hearts ? ' · 间隔 ${settings.heartIntervalSeconds.toStringAsFixed(1)} 秒' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
            if (!compact) ...[const SizedBox(height: 16), play],
            SizedBox(height: compact ? 6 : 10),
            Row(
              children: [
                Expanded(
                  child: _shortcut(
                    key: const Key('start-fullscreen'),
                    label: '进入全屏',
                    icon: Icons.fullscreen_rounded,
                    onPressed: onStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Tooltip(
                    message: '调整',
                    child: _shortcut(
                      label: '调整',
                      icon: Icons.tune_rounded,
                      onPressed: onAdjust,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shortcut({
    Key? key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) => FilledButton.tonal(
    key: key,
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      textStyle: const TextStyle(fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
