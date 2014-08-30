library bwu_testrunner.shared.response_collector;

import 'dart:async' as async;
import 'package:bwu_testrunner/shared/message.dart';


/**
 * Creates a [async.Future] (that can be accessed using the [future] getter)
 * which completes with the response messages after all expected response
 * messages are arrived.
 * If they don't arrive in time the [async.Future] completes with a [Timeout]
 * message.
 */
class ResponseCollector {

  /// A static list that references all active [ResponseCollector]s.
  static final List<ResponseCollector> _listeners = [];

  final async.Completer completer = new async.Completer<Message>();
  /// The future that completes when all responses are arrived or when the
  /// timeout has reached.
  async.Future get future => completer.future;

  /// The original request message.
  final Message request;

  /// The list of sub-requests created for [request].
  final Map<String,async.Future> _subRequests = {};

  /// The list of response messages already arrived.
  final Map<String,Response> results = {};

  Duration _timeout;
  ResponseCollector(this.request, {Duration timeout}) {
    _listeners.add(this);
    _timeout = timeout;
    if(_timeout == null) {
      _timeout = new Duration(seconds: 120);
    }
    completer.future.timeout(_timeout, onTimeout: _timeoutHandler);
  }

  /// When all [subRequests] have been added start waiting for the responses.
  void wait() {
    _subRequests.forEach((mId, req) {
      req.then((response) {
        results[mId] = response;
        _checkComplete();
      })
      ..timeout(new Duration(seconds: 25), onTimeout: () {
        //_subRequests.forEach((k, v) {
          if(!results.containsKey(mId)) {
            results[mId] = new Timeout()..responseId = mId;
          }
        //});
        _checkComplete();
      });
    });
    //async.Future.wait(subRequests).then((values) {
      //_cleanup();
//      if (!completer.isCompleted) { // due to timeout
//        completer.complete(new MessageList()
//          ..responseId = request.messageId
//          ..messages.addAll(values));
//      }
//    });
  }

  void _checkComplete() {
    if (_subRequests.length == results.length) {
      _cleanup();
      completer.complete(new MessageList()
        ..responseId = request.messageId
        ..messages.addAll(results.values));
    }
  }

    void addSubRequest(String messageId, async.Future request) {
    _subRequests[messageId] = request;
  }

  /// Remove this instance from the list of active [ResponseCollector]s.
  void _cleanup() {
    _listeners.remove(this);
  }

  /// Handle timeout - send Timeout response message.
  void _timeoutHandler() {
    _cleanup();
    completer.complete(new Timeout());
  }

  /// Stop waiting for and processing of any arriving messages.
  void cancel() {
    _cleanup();
  }
}
