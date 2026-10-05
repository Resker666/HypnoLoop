import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'mode_selector.dart';
import 'preview_controls.dart';
import 'settings.dart';
import 'settings_panel.dart';

class AdjustmentPanel extends StatefulWidget {
  const AdjustmentPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onCommit,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onCommit;

  @override
  State<AdjustmentPanel> createState() => _AdjustmentPanelState();
}

class _AdjustmentPanelState extends State<AdjustmentPanel> {
  SettingsSection _section = SettingsSection.shape;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModeSelector(
                value: widget.settings.kind,
                onChanged: (kind) {
                  widget.onChanged(widget.settings.copyWith(kind: kind));
                  widget.onCommit();
                },
              ),
              const SizedBox(height: 20),
              CupertinoSlidingSegmentedControl<SettingsSection>(
                groupValue: _section,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLowest,
                thumbColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                onValueChanged: (section) {
                  if (section != null) setState(() => _section = section);
                },
                children: {
                  for (final section in SettingsSection.values)
                    section: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(
                        section == SettingsSection.shape ? '参数' : '配色',
                      ),
                    ),
                },
              ),
              if (_section == SettingsSection.shape) ...[
                const SizedBox(height: 20),
                PlaybackSpeedControl(
                  settings: widget.settings,
                  onChanged: widget.onChanged,
                  onChangeEnd: widget.onCommit,
                ),
              ],
            ],
          ),
        ),
        SettingsPanel(
          settings: widget.settings,
          section: _section,
          onChanged: widget.onChanged,
          onChangeEnd: widget.onCommit,
        ),
      ],
    ),
  );
}
