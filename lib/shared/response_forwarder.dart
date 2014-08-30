library bwu_testrunner.shared.response_forwarder;

import 'dart:io' as io;
import 'dart:async' as async;
import 'package:bwu_testrunner/shared/message.dart';

class SocketMessageSink  {
  io.WebSocket _socket;

  SocketMessageSink(this._socket);

  void call(Message message) {
    print('Forward: ${message.toJson()}');
    _socket.add(message.toJson());
  }
}

typedef Message ResponseCallback(Message request, Message response);

/**
 * Waits for a response and forwards it to a MessageSink.
 * The ResponseCallback allows to modify the response before it is sent.
 */
class ResponseForwarder {

  static final List<ResponseForwarder> _listeners = [];

  final Message _request;
  final MessageSink _messageSink;
  async.Timer _timeout;

  async.StreamSubscription _responseSubscription;
  ResponseCallback _responseCallback;

  ResponseForwarder(this._request, async.Stream responseStream, this._messageSink, {ResponseCallback responseCallback,  Duration timeout}) {
    if(responseCallback != null) {
      _responseCallback = responseCallback;
    } else {
      _responseCallback = (Request request, Response response) => response..responseId = request.messageId;
    }
    _listeners.add(this);
    _responseSubscription = responseStream.listen(_responseHandler);
    var to = timeout;
    if(to == null) {
      to = new Duration(seconds: 120);
    }
    _timeout = new async.Timer(to, _timeoutHandler);
  }

  void _responseHandler(Response response) {
    if(response.responseId != _request.messageId) {
      return;
    }
    _cleanup();
    if(_timeout != null) {
      _timeout.cancel();
    }
    _messageSink(_responseCallback(_request, response));
  }

  void _cleanup() {
    if(_timeout != null) {
      _timeout.cancel();
    }
    if(_responseSubscription != null) {
      _responseSubscription.cancel();
    }
    _listeners.remove(this);
  }

  void _timeoutHandler() {
    _cleanup();

    _messageSink(_responseCallback(_request, new Timeout()));
  }

  void cancel() {
    _cleanup();
  }
}
