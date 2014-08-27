library bwu_testrunner.client.connection;

import 'dart:async' as async;
import 'dart:html' as dom;
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_testrunner/shared/response_completer.dart';
import 'package:bwu_testrunner/shared/response_collector.dart';

/**
 * Manages the WebSocket connection to the BWU Testrunner server and provides
 * an API to allow easy access to the servers functionality.
 */
class Connection {

  dom.WebSocket _socket;
  bool _isConnected = false;
  /// A list of all test files.
  TestList testList;

  /// Connect to the server.
  async.Future<bool> connect(int port) {
    var completer = new async.Completer();

    _socket = new dom.WebSocket('ws://localhost:${port}')
        ..onMessage.listen((dom.MessageEvent e) {
           _onReceive.add(new Message.fromJson(e.data));
        })
        ..onClose.listen(_onDone)
        ..onError.listen(print)
        ..onOpen.first.then((_) {
          print('Connected');
          completer.complete(true);
        });

    return completer.future;
  }

  /// All messages received from the server are added to this stream.
  async.StreamController<Message> _onReceive = new async.StreamController<Message>.broadcast();
  /// Allows to subscribe to the received messages stream.
  async.Stream get onReceive => _onReceive.stream;

  /// Handles the connection close event.
  void _onDone(dom.CloseEvent e) {
    print('Disconnected');
    _isConnected = false;
  }

  /// Sends a request to the server to return a list of know test files and
  /// all the tests they contain.
  async.Future<Message> requestTestList() {
    var request = new TestListRequest();
    var future =  new ResponseCompleter(request.responseId, onReceive).future;
    _socket.send(request.toJson());
    return future;
  }

  /// Sends a request to the server to execute all or specific tests of a file
  /// and to return the results of the test runs.
  async.Future<Message> runFileTestsRequest(String filePath, [List<int> testIds]) {
    RunFileTestsRequest request = new RunFileTestsRequest()
        ..path = filePath;
    if(testIds != null) {
      request.testIds.addAll(testIds);
    }
    var future =  new ResponseCompleter(request.responseId, onReceive).future;
    _socket.send(request.toJson());
    return future;
  }

  /// Sends one request for each test file to the server to execute all tests
  /// in the file.
  async.Future<Message> runAllTestsRequest() {
    var request = new RunFileTestsRequest();
    var future =  new ResponseCollector(request).future;
    var requests = <async.Future>[];
    testList.consoleTestFiles.forEach((ctf) {
      runFileTestsRequest(ctf.path);
    });
    async.Future.wait(requests)
    .then((responses) {
       responses.forEach((r) {
         print('runFileTestsResponse: $r');
      });
    });

    _socket.send(request.toJson());
    return future;
  }
}
