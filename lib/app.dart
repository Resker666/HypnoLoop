import 'dart:async';
import 'package:flutter/material.dart';
import 'features/player/player_page.dart';
import 'features/player/playback_clock.dart';
import 'features/player/settings_controller.dart';
import 'features/player/settings_store.dart';
import 'platform/display_controller.dart';
import 'platform/launcher_icon_controller.dart';

class HypnoLoopApp extends StatefulWidget {
  const HypnoLoopApp({super.key, this.store, this.display});
  final SettingsStore? store;
  final DisplayController? display;
  @override
  State<HypnoLoopApp> createState() => _HypnoLoopAppState();
}

class _HypnoLoopAppState extends State<HypnoLoopApp> {
  final _clock = PlaybackClock();
  final _launcherIcons = LauncherIconController();
  late final _display = widget.display ?? DisplayController();
  late final _settings = SettingsController(
    widget.store ?? PreferencesSettingsStore(),
  );
  late final Future<void> _loaded;

  @override
  void initState() {
    super.initState();
    _loaded = _settings.load();
    unawaited(_launcherIcons.load());
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HypnoLoop',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB69AFF),
        brightness: Brightness.dark,
        surface: const Color(0xFF171321),
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0B15),
      sliderTheme: const SliderThemeData(trackHeight: 3),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF171321),
      ),
    ),
    home: FutureBuilder<void>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => Stack(
            children: [
              PlayerPage(
                settings: _settings.settings,
                onSettingsChanged: _settings.update,
                onCommitSettings: _settings.flush,
                clock: _clock,
                display: _display,
                launcherIcons: _launcherIcons,
              ),
              if (_settings.saveFailed)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Material(
                        color: const Color(0xFF34223B),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('设置未能保存'),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
  @override
  void dispose() {
    unawaited(_settings.flush().whenComplete(_settings.dispose));
    _clock.dispose();
    _launcherIcons.dispose();
    super.dispose();
  }
}
