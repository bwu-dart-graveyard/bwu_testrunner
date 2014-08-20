library bwu_testrunner.shared.response_collector;

import 'dart:async' as async;
import 'package:bwu_testrunner/shared/message.dart';

class ResponseCollector {

  static final List<ResponseCollector> _listeners = [];

  final async.Completer completer = new async.Completer<Message>();
  async.Future get future => completer.future;

  final Message request;
  final List<async.Future> subRequests = [];
  final List<Message> results = [];

  ResponseCollector(this.request, {Duration timeout}) {
    _listeners.add(this);
    var to = timeout;
    if(to == null) {
      to = new Duration(seconds: 120);
    }
    completer.future.timeout(to, onTimeout: _timeoutHandler);
  }

  void wait() {
    async.Future.wait(subRequests).then((values) {
      _cleanup();
      completer.complete(new MessageList()
        ..responseId = request.messageId
        ..messages.addAll(values));
    });
  }

  void _cleanup() {
//    if(_responseSubscription != null) {
//      _responseSubscription.cancel();
//    }
    _listeners.remove(this);
  }

  void _timeoutHandler() {
    _cleanup();
    completer.complete(new Timeout());
  }

  void cancel() {
    _cleanup();
  }
}