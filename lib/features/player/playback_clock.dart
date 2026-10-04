import 'package:flutter/foundation.dart';

class PlaybackClock extends ChangeNotifier {
  double _seconds = 0;
  double _speed = .5;
  bool _playing = true;
  bool _foreground = true;
  double get animationSeconds => _seconds;
  bool get isPlaying => _playing;
  bool get isAdvancing => _playing && _foreground;

  void advance(Duration delta) {
    if (!isAdvancing || delta.inMicroseconds <= 0) return;
    _seconds += delta.inMicroseconds / Duration.microsecondsPerSecond * _speed;
    notifyListeners();
  }

  void setPlaying(bool value) {
    if (_playing == value) return;
    _playing = value;
    notifyListeners();
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    notifyListeners();
  }

  void setSpeed(double value) {
    final checked = value.isFinite ? value.clamp(.1, 2).toDouble() : .5;
    if (_speed == checked) return;
    _speed = checked;
    notifyListeners();
  }
}
