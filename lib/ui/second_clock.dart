import 'dart:async';

import 'package:flutter/widgets.dart';

/// One shared clock that ticks exactly on each whole-second boundary of the
/// real (epoch) clock. The next delay is recomputed from the current time on
/// every tick, so it never drifts the way a fixed 1 s periodic timer would.
class SecondClock extends ChangeNotifier with WidgetsBindingObserver {
  SecondClock({DateTime Function()? nowFn}) : _nowFn = nowFn ?? DateTime.now {
    _now = _nowFn();
  }

  final DateTime Function() _nowFn;
  late DateTime _now;
  Timer? _timer;

  DateTime get now => _now;

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void _schedule() {
    final ms = _nowFn().millisecondsSinceEpoch;
    // A few ms past the boundary so we land inside the new second.
    final delay = 1000 - (ms % 1000) + 5;
    _timer = Timer(Duration(milliseconds: delay), () {
      _now = _nowFn();
      notifyListeners();
      _schedule();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _timer != null) {
      _timer!.cancel();
      _now = _nowFn();
      notifyListeners();
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
