library bwu_testrunner.server;

import 'dart:io' as io;
import 'dart:async' as async;
import 'testfiles.dart';
import 'package:bwu_testrunner/server/isolate_launcher.dart';
import 'package:bwu_testrunner/shared/message.dart';

class TestrunnerServer {

  TestFiles testfiles;
  final listenPort = 18070;

  io.Directory testDirectory;

  TestrunnerServer(this.testDirectory, {Function onReady}) {
    testfiles = new TestFiles(testDirectory);

    io.HttpServer.bind('127.0.0.1', listenPort)
    .then((server) {
      serve(server);
      if(onReady != null) {
        onReady(listenPort);
      }
    });
  }

  void serve(io.HttpServer server) {
    server.listen((request) {
      if(io.WebSocketTransformer.isUpgradeRequest(request)) {
        io.WebSocketTransformer.upgrade(request).then(handleWebsocket);
      } else {
        print("Regular ${request.method} for: ${request.uri.path}");
      }
    });
  }

  final listeners = <io.WebSocket>[];

  void handleWebsocket(io.WebSocket socket) {
    listeners.add(socket);
    testfiles.onTestfilesChanged.listen(testFilesChangedHandler);
    socket.listen((String s) {
      var c = new Message.fromJson(s);
      print('Client sent: $s');

      switch(c.messageType) {
        case TestListRequest.MESSAGE_TYPE:
          testListRequestHandler(socket, c);
          break;

        case RunFileTestsRequest.MESSAGE_TYPE:
          runFileTestsRequestHandler(socket, c);
          break;
      }
    },
    onDone: () {
      listeners.remove(socket);
      print('Client disconnected');
    });
  }

  Map<String, async.StreamSubscription> _subscriptions = {};
  Map<String, Message> _respondTo = {};
  Map<String,Message> _waitForResponse = {};
  Map<String,String> _isolateMessageId2ClientMessageId = {};

  void runFileTestsRequestHandler(io.WebSocket socket, RunFileTestsRequest clientRequest) {
    var response = new FileTestsResult()
        ..responseId = clientRequest.messageId
        ..socket = socket;
    _respondTo[response.messageId] = response;

    var isolateLauncher = new IsolateLauncher(
        testfiles.consoleTestfiles.firstWhere((ctf) => ctf.path == clientRequest.path));

    _subscriptions[clientRequest.messageId] = isolateLauncher.onReceive.listen((Message isolateResponse) {
      if(isolateResponse is! FileTestsResult) {
        return;
      }
      _waitForResponse.remove(isolateResponse.responseId);
      FileTestsResult clientResponse = _respondTo[_isolateMessageId2ClientMessageId[isolateResponse.responseId]];
      _isolateMessageId2ClientMessageId.remove(isolateResponse.responseId);
      clientResponse.socket.add(isolateResponse.toJson());
      _respondTo.remove(clientResponse.messageId);
      var subscr = _subscriptions.remove(clientResponse.responseId);
      if(subscr != null) subscr.cancel();

    });
    isolateLauncher.launch()

    .then((IsolateLauncher l) {
      var isolateRequest = clientRequest
          ..responseId = response.messageId;

//      var isolateRequest = new FileTestListRequest()
//          ..path = e.path
//          ..responseId = response.messageId;

      _waitForResponse[isolateRequest.messageId] = isolateRequest;
      _isolateMessageId2ClientMessageId[isolateRequest.messageId] = response.messageId;
      l.send(isolateRequest);
    });
  }

  void testListRequestHandler(io.WebSocket socket, TestListRequest clientRequest) {

    var response = new TestList()
        ..responseId = clientRequest.messageId
        ..socket = socket;
    _respondTo[response.messageId] = response;

    testfiles.consoleTestfiles.forEach((e) {
      var isolateLauncher = new IsolateLauncher(e);

      // process isolate response
      _subscriptions[response.responseId] = isolateLauncher.onReceive.listen((Message isolateResponse) {
        if(isolateResponse is! ConsoleTestFile) {
          return;
        }
        _waitForResponse.remove(isolateResponse.responseId);
        TestList clientResponse = _respondTo[_isolateMessageId2ClientMessageId[isolateResponse.responseId]];
        _isolateMessageId2ClientMessageId.remove(isolateResponse.responseId);
        clientResponse.consoleTestfiles.add(isolateResponse);

        if(!_isolateMessageId2ClientMessageId.values.contains(clientResponse.messageId)) {
          clientResponse.socket.add(clientResponse.toJson());
          _respondTo.remove(clientResponse.messageId);
          var subscr = _subscriptions.remove(clientResponse.responseId);
          if(subscr != null) subscr.cancel();
        }
      });
      isolateLauncher.launch()

      .then((IsolateLauncher l) {
        // create isolate request

        var isolateRequest = new FileTestListRequest()
            ..path = e.path
            ..responseId = response.messageId;

        _waitForResponse[isolateRequest.messageId] = isolateRequest;
        _isolateMessageId2ClientMessageId[isolateRequest.messageId] = response.messageId;
        l.send(isolateRequest);
      });

    });

    testfiles.htmlTestfiles.forEach((e, f) {
      // TODO(zoech) handle HTML tests
      // response.htmlTestfiles.add(new HtmlTestfile()..path = e.path);
    });
  }

  void testFilesChangedHandler(_) {
    listeners.forEach((l) => l.add('Testfiles changed'));
  }

}

