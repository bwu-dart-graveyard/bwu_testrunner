library bwu_testrunner.shared.response_forwarder;

import 'dart:io' as io;
import 'dart:async' as async;
import 'package:bwu_testrunner/shared/message.dart';

class SocketMessageSink extends MessageSink {
  io.WebSocket _socket;

  SocketMessageSink(this._socket);

  void send(Message message) {
    _socket.add(message.toJson());
  }
}

typedef Message ResponseCallback(Message request, Message response);

/// Waits for a response and forwards it to a MessageSink.
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
      _responseCallback = (Message request, Message response) => response..responseId = request.messageId;
    }
    _listeners.add(this);
    _responseSubscription = responseStream.listen(_responseHandler);
    var to = timeout;
    if(to == null) {
      to = new Duration(seconds: 120);
    }
    _timeout = new async.Timer(to, _timeoutHandler);
  }

  void _responseHandler(Message response) {
    if(response.responseId != _request.messageId) {
      return;
    }
    _cleanup();
    if(_timeout != null) {
      _timeout.cancel();
    }
    _messageSink.send(_responseCallback(_request, response));
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

    _messageSink.send(_responseCallback(_request, new Timeout()));
  }

  void cancel() {
    _cleanup();
  }
}