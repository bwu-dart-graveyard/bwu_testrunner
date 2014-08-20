library bwu_testrunner.shared.response_completer;

import 'dart:async' as async;
import 'package:bwu_testrunner/shared/message.dart';

class ResponseCompleter {

  static final List<ResponseCompleter> _listeners = [];

  final async.Completer completer = new async.Completer<Message>();
  async.Future get future => completer.future;
  async.StreamSubscription _responseSubscription;

  final String _responseId;

  ResponseCompleter(this._responseId, async.Stream responseStream, {Duration timeout}) {
    _listeners.add(this);
    _responseSubscription = responseStream.listen(_responseHandler);
    var to = timeout;
    if(to == null) {
      to = new Duration(seconds: 120);
    }
    completer.future.timeout(to, onTimeout: _timeoutHandler);
  }

  void _responseHandler(Message message) {
    if(message.responseId != _responseId) {
      return;
    }
    _cleanup();
    completer.complete(message);
  }

  void _cleanup() {
    if(_responseSubscription != null) {
      _responseSubscription.cancel();
    }
    _listeners.remove(this);
  }

  void _timeoutHandler() {
    _cleanup();
    completer.complete(new Timeout()..responseId = _responseId);
  }

  void cancel() {
    _cleanup();
  }
}

