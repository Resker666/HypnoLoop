import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../platform/display_controller.dart';
import 'painters.dart';
import 'playback_clock.dart';
import 'settings.dart';
import 'settings_panel.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onCommitSettings,
    required this.clock,
    required this.display,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function() onCommitSettings;
  final PlaybackClock clock;
  final DisplayController display;
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

  Future<void> _showSettings() async {
    _settingsOpen = true;
    _hideTimer?.cancel();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .85,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '播放设置',
                        style: TextStyle(
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
              Expanded(
                child: ValueListenableBuilder<AppSettings>(
                  valueListenable: _panelSettings,
                  builder: (_, settings, _) => SettingsPanel(
                    settings: settings,
                    onChanged: _changeSettings,
                    onChangeEnd: () => unawaited(widget.onCommitSettings()),
                  ),
                ),
              ),
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
          color: const Color(0xE61C1828),
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

  Widget _preview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _canvas(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: widget.clock.isPlaying ? '暂停' : '继续',
              onPressed: _pause,
              icon: Icon(
                widget.clock.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('start-fullscreen'),
                onPressed: _start,
                icon: const Icon(Icons.fullscreen_rounded),
                label: const Text('开始全屏'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Center(
        child: Text(
          '全屏后轻点画面，即可暂停或退出',
          style: TextStyle(color: Color(0xFFABA6BC), fontSize: 12),
        ),
      ),
      const SizedBox(height: 16),
    ],
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
          if (_fullscreen)
            Positioned.fill(child: _canvas())
          else
            SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 22,
                          color: Color(0xFFCEB9FF),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'HypnoLoop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.8,
                            ),
                          ),
                        ),
                        Text(
                          '光 · 形 · 循环',
                          style: TextStyle(
                            color: Color(0xFFABA6BC),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final panel = SettingsPanel(
                          settings: widget.settings,
                          onChanged: _changeSettings,
                          onChangeEnd: () =>
                              unawaited(widget.onCommitSettings()),
                        );
                        if (constraints.maxWidth >
                            constraints.maxHeight * 1.3) {
                          return Row(
                            children: [
                              Expanded(child: _preview()),
                              SizedBox(width: 330, child: panel),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Expanded(flex: 5, child: _preview()),
                            Expanded(
                              flex: 4,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF171321),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),
                                child: panel,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
