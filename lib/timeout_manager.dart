library bwu_testrunner.timeout_manager;

import 'dart:async' as async;

class TimeoutManager {
  Function onTimeout;
  Duration timeoutDuration;
  async.Timer _timer;
  DateTime lastUpdate;

  TimeoutManager(this.timeoutDuration, this.onTimeout) {
    assert(onTimeout != null);
  }

  void update() {
    if(_timer != null) {
      _timer.cancel();
    }
    lastUpdate = new DateTime.now();

    _timer = new async.Timer(timeoutDuration, () {
      onTimeout();
    });
  }

  void cancel() => _timer.cancel();
}
