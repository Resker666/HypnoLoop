import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../platform/display_controller.dart';
import '../../platform/launcher_icon_controller.dart';
import '../launcher_icons/launcher_icon_picker.dart';
import 'adjustment_panel.dart';
import 'painters.dart';
import 'playback_clock.dart';
import 'preview_controls.dart';
import 'settings.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onCommitSettings,
    required this.clock,
    required this.display,
    this.launcherIcons,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function() onCommitSettings;
  final PlaybackClock clock;
  final DisplayController display;
  final LauncherIconController? launcherIcons;
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final ValueNotifier<AppSettings> _panelSettings;
  Duration? _previousTick;
  Timer? _hideTimer;
  bool _fullscreen = false, _controls = false, _settingsOpen = false;
  Future<void> _displayQueue = Future.value();
  String? _displayError;

  @override
  void initState() {
    super.initState();
    _panelSettings = ValueNotifier(widget.settings);
    widget.clock.setSpeed(widget.settings.speed);
    widget.clock.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addObserver(this);
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_panelSettings.value != widget.settings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _panelSettings.value = widget.settings;
      });
    }
    widget.clock.setSpeed(widget.settings.speed);
  }

  void _changeSettings(AppSettings settings) {
    _panelSettings.value = settings;
    widget.onSettingsChanged(settings);
  }

  void _tick(Duration elapsed) {
    final previous = _previousTick;
    _previousTick = elapsed;
    if (previous != null) widget.clock.advance(elapsed - previous);
  }

  void _syncPlayback() {
    _previousTick = null;
    if (widget.clock.isAdvancing && !_ticker.isActive) _ticker.start();
    if (!widget.clock.isAdvancing && _ticker.isActive) _ticker.stop();
    final fullscreen = _fullscreen;
    final awake = widget.clock.isAdvancing;
    _displayQueue = _displayQueue.then((_) async {
      try {
        await widget.display.apply(fullscreen: fullscreen, keepAwake: awake);
        if (mounted && _displayError != null) {
          setState(() => _displayError = null);
        }
      } catch (_) {
        if (mounted) setState(() => _displayError = '显示模式切换失败');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.clock.setForeground(state == AppLifecycleState.resumed);
    _syncPlayback();
    if (state == AppLifecycleState.resumed && widget.launcherIcons != null) {
      unawaited(widget.launcherIcons!.load());
    }
    if (state != AppLifecycleState.resumed) {
      unawaited(widget.onCommitSettings());
    }
  }

  void _autoHide() {
    _hideTimer?.cancel();
    if (!_fullscreen || !_controls || _settingsOpen) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    if (!_fullscreen) return;
    setState(() => _controls = !_controls);
    _autoHide();
  }

  void _start() {
    setState(() {
      _fullscreen = true;
      _controls = false;
    });
    _syncPlayback();
  }

  void _exit() {
    _hideTimer?.cancel();
    setState(() {
      _fullscreen = false;
      _controls = false;
    });
    _syncPlayback();
    unawaited(widget.onCommitSettings());
  }

  void _pause() {
    setState(() => widget.clock.setPlaying(!widget.clock.isPlaying));
    _syncPlayback();
    _autoHide();
  }

  Future<void> _showPanel({
    required String title,
    required WidgetBuilder builder,
    Key? key,
  }) async {
    if (_settingsOpen) return;
    _settingsOpen = true;
    _hideTimer?.cancel();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .9,
        child: SafeArea(
          top: false,
          child: Column(
            key: key,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭设置',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(child: builder(context)),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    _settingsOpen = false;
    _autoHide();
    unawaited(widget.onCommitSettings());
  }

  Future<void> _showSettings() => _showPanel(
    title: '调整',
    key: const Key('adjustment-sheet'),
    builder: (_) => ValueListenableBuilder<AppSettings>(
      valueListenable: _panelSettings,
      builder: (_, settings, _) => AdjustmentPanel(
        settings: settings,
        showSpeed: _fullscreen,
        onChanged: _changeSettings,
        onCommit: () => unawaited(widget.onCommitSettings()),
      ),
    ),
  );

  Future<void> _showLauncherIcons() => _showPanel(
    title: '外观设置',
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: LauncherIconPicker(controller: widget.launcherIcons!),
    ),
  );

  Widget _canvas() => GestureDetector(
    onTap: _toggleControls,
    child: RepaintBoundary(
      child: ClipRect(
        child: CustomPaint(
          key: const Key('animation-canvas'),
          size: Size.infinite,
          painter: widget.settings.kind == AnimationKind.spiral
              ? SpiralPainter(settings: widget.settings, clock: widget.clock)
              : HeartsPainter(settings: widget.settings, clock: widget.clock),
        ),
      ),
    ),
  );

  Widget _toolbar() => SafeArea(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          key: const Key('player-toolbar'),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: widget.clock.isPlaying ? '暂停' : '继续',
                  onPressed: _pause,
                  icon: Icon(
                    widget.clock.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  tooltip: '设置',
                  onPressed: _showSettings,
                  icon: const Icon(Icons.tune_rounded),
                ),
                IconButton(
                  tooltip: '退出全屏',
                  onPressed: _exit,
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _preview() => ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: Stack(
      children: [
        Positioned.fill(child: _canvas()),
        Positioned(
          left: 16,
          top: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                widget.settings.kind == AnimationKind.spiral
                    ? '螺旋 · 预览'
                    : '爱心 · 预览',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _previewControls({bool compact = false}) => PreviewControls(
    settings: widget.settings,
    playing: widget.clock.isPlaying,
    onChanged: _changeSettings,
    onCommit: () => unawaited(widget.onCommitSettings()),
    onPause: _pause,
    onStart: _start,
    onAdjust: _showSettings,
    compact: compact,
  );

  Widget _home() => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 14, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'HypnoLoop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              if (widget.launcherIcons != null)
                IconButton(
                  tooltip: '桌面图标',
                  onPressed: _showLauncherIcons,
                  icon: const Icon(Icons.settings_outlined, size: 22),
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > constraints.maxHeight * 1.3) {
                final compact =
                    constraints.maxHeight < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                final panelWidth = compact
                    ? (constraints.maxWidth * .7)
                          .clamp(350.0, 480.0)
                          .clamp(0.0, constraints.maxWidth - 112)
                    : 330.0;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(child: _preview()),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: panelWidth,
                        child: _previewControls(compact: compact),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _preview(),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _previewControls(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_fullscreen,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _fullscreen) _exit();
    },
    child: Scaffold(
      body: Stack(
        children: [
          if (_fullscreen) Positioned.fill(child: _canvas()) else _home(),
          if (_fullscreen && _controls) _toolbar(),
          if (_displayError != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: const Color(0xE61C1828),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_displayError!),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _ticker.dispose();
    _panelSettings.dispose();
    final display = widget.display;
    unawaited(
      _displayQueue.then((_) => display.restore()).catchError((Object _) {}),
    );
    unawaited(widget.onCommitSettings());
    super.dispose();
  }
}
