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
  final List<async.Future> subRequests = [];

  /// The list of response messages already arrived.
  final List<Message> results = [];

  ResponseCollector(this.request, {Duration timeout}) {
    _listeners.add(this);
    var to = timeout;
    if(to == null) {
      to = new Duration(seconds: 120);
    }
    completer.future.timeout(to, onTimeout: _timeoutHandler);
  }

  /// When all [subRequests] have been added start waiting for the responses.
  void wait() {
    async.Future.wait(subRequests).then((values) {
      _cleanup();
      if (!completer.isCompleted) { // due to timeout
        completer.complete(new MessageList()
          ..responseId = request.messageId
          ..messages.addAll(values));
      }
    });
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
