library bwu_testrunner.server;

import 'dart:io' as io;
import 'dart:async' as async;
import 'testfiles.dart';
import 'package:bwu_testrunner/server/isolate_launcher.dart';
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_testrunner/shared/response_forwarder.dart';
import 'package:bwu_testrunner/shared/response_collector.dart';
import 'package:bwu_testrunner/shared/response_completer.dart';

/***
 * The testrunner server implementation.
 */
class TestrunnerServer {

  /// Contains the references to the found test files and the directory watcher.
  TestFiles testfiles;

  /// The port the server listens to websocket connect requests.
  final servePort = 18070;

  /// The directory containing the test files.
  io.Directory testDirectory;

  TestrunnerServer(this.testDirectory, {Function onReady}) {
    testfiles = new TestFiles(testDirectory);

    io.HttpServer.bind('127.0.0.1', servePort)
    .then((server) {
      _serve(server);
      if(onReady != null) {
        onReady(servePort);
      }
    });
  }

  void _serve(io.HttpServer server) {
    server.listen((request) {
      if(io.WebSocketTransformer.isUpgradeRequest(request)) {
        io.WebSocketTransformer.upgrade(request).then(_handleWebsocket);
      } else {
        print("Regular ${request.method} for: ${request.uri.path}");
      }
    });
  }

  /// Connected clients.
  final connectedClients = <io.WebSocket>[];

  /// Handle incoming connections.
  void _handleWebsocket(io.WebSocket socket) {
    connectedClients.add(socket);
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
      connectedClients.remove(socket);
      print('Client disconnected');
    });
  }


  // process RunFileTestsRequest
  void runFileTestsRequestHandler(io.WebSocket socket,
                                  RunFileTestsRequest clientRequest) {

    var isolateLauncher = new IsolateLauncher(
        testfiles.consoleTestfiles.firstWhere(
            (ctf) => ctf.path == clientRequest.path));

    new ResponseForwarder(clientRequest, isolateLauncher.onReceive,
        new SocketMessageSink(socket));

    isolateLauncher.launch()
    .then((IsolateLauncher l) {
      l.send(clientRequest);
    });
  }

  // process TestListRequest
  void testListRequestHandler(io.WebSocket socket, TestListRequest clientRequest) {

    var responseCollector = new ResponseCollector(clientRequest);

    new ResponseForwarder(clientRequest, responseCollector.future.asStream(),
        new SocketMessageSink(socket), responseCallback:
          (Message request, Message response) {
      TestList clientResponse = new TestList()
          ..responseId = request.messageId;

      if(response is MessageList) {
        response.messages.forEach((Message m) {
          if(m is ConsoleTestFile) {
            clientResponse.consoleTestfiles.add(m);
          } else if(Message is HtmlTestFile) {
            clientResponse.htmlTestfiles.add(m);
          } else {
            throw 'Unsupported messagetype "${response.messageType}".';
          }
        });
        return clientResponse;
      } else if (response is Timeout) {
        return response..responseId = request.messageId;
      }
    });

    testfiles.consoleTestfiles.forEach((e) {
      var isolateLauncher = new IsolateLauncher(e);

      var isolateRequest = new FileTestListRequest()
          ..path = e.path;

      responseCollector.subRequests.add(new ResponseCompleter(isolateRequest.messageId, isolateLauncher.onReceive).future);

      isolateLauncher.launch()
      .then((IsolateLauncher l) {
        l.send(isolateRequest);
      });

    });

    testfiles.htmlTestfiles.forEach((e, f) {
      // TODO(zoech) handle HTML tests
      // can't be run in isolates, needs content_shell
      // response.htmlTestfiles.add(new HtmlTestfile()..path = e.path);
    });

    responseCollector.wait();
  }

  void testFilesChangedHandler(TestFileChanged event) {
    connectedClients.forEach((l) => l.add(event.toJson()));
  }

}

