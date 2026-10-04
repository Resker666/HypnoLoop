import 'package:flutter/material.dart';
import 'features/player/player_page.dart';
import 'features/player/playback_clock.dart';
import 'features/player/settings.dart';
import 'platform/display_controller.dart';

class HypnoLoopApp extends StatefulWidget {
  const HypnoLoopApp({super.key});
  @override
  State<HypnoLoopApp> createState() => _HypnoLoopAppState();
}

class _HypnoLoopAppState extends State<HypnoLoopApp> {
  final _clock = PlaybackClock();
  final _display = DisplayController();
  AppSettings _settings = AppSettings.defaults().preset(1);

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
    home: PlayerPage(
      settings: _settings,
      onSettingsChanged: (value) => setState(() => _settings = value),
      onCommitSettings: () async {},
      clock: _clock,
      display: _display,
    ),
  );
  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }
}
