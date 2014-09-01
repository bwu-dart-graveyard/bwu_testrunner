library bwu_testrunner.shared.response_completer;

import 'dart:async' as async;
import 'package:bwu_testrunner/shared/message.dart';

/**
 * Creates a [async.Completer] and when a response to the message arrives
 * the [future] completes with the received message.
 * When the response doesn't arrive within the timeout [Duration] the
 * [async.Future] completes with a [Timeout] message.
 */
class ResponseCompleter {

  /// A static list that references all active [ResponseCompleter]s.
  static final List<ResponseCompleter> _listeners = [];

  final async.Completer completer = new async.Completer<Message>();

  /// The [async.Future] to wait for the response to arrive.
  async.Future get future => completer.future;

  /// The stream where the response will arrive.
  async.StreamSubscription _responseSubscription;

  /// The id of the request message to wait for responses.
  final Request _request;

  ResponseCompleter(this._request, async.Stream responseStream, {Duration timeout}) {
    _listeners.add(this);
    _responseSubscription = responseStream.listen(_responseHandler);
    var to = timeout;
    if(to == null) {
      to = new Duration(seconds: 120);
    }
    completer.future.timeout(to, onTimeout: _timeoutHandler);
  }

  /// Check if the received message is the response we are waiting for and
  /// complete the [async.Future] if it is.
  void _responseHandler(Response response) {
    if(response.responseId != _request.messageId) {
      return;
    }
    _cleanup();
    completer.complete(response);
  }

  void _cleanup() {
    if(_responseSubscription != null) {
      _responseSubscription.cancel();
    }
    _listeners.remove(this);
  }

  void _timeoutHandler() {
    _cleanup();
    completer.complete(_request.timedOutResponse());
  }

  void cancel() {
    _cleanup();
  }
}

