library bwu_testrunner.client.connection;

import 'dart:async' as async;
import 'dart:html' as dom;
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_testrunner/shared/response_completer.dart';


class Connection {

  dom.WebSocket _socket;
  bool _isConnected = false;

  async.Future<bool> connect(int port) {
    var compl = new async.Completer();
    print('server ready');
    _socket = new dom.WebSocket('ws://localhost:${port}')
        ..onMessage.listen((json) => _onReceive.add(new Message.fromJson(json.data)))
        ..onClose.listen(_onDone)
        ..onError.listen(print)
        ..onOpen.first.then((_) => compl.complete(true));
    return compl.future;
  }

  async.StreamController<Message> _onReceive = new async.StreamController<Message>.broadcast();
  async.Stream get onReceive => _onReceive.stream;

  async.Future<Message> requestTestList() {
    var request = new TestListRequest();
    var future =  new ResponseCompleter(request.responseId, onReceive).future;
    _socket.send(request.toJson());
    return future;
  }

//  void _onData(String json) {
//    var message = new Message.fromJson(json);
//    var testfile;
//    print('Client: ${message.toJson()}');
//    switch(message.messageType) {
//      case TestList.MESSAGE_TYPE:
//        testfile = message.consoleTestfiles.firstWhere((e) =>
//            e.path == 'test/console_launcher/src/group_with_one_failing_test.dart');
//        _socket.add((new RunFileTestsRequest()
//          ..path = testfile.path
//          ..testIds.add(1))
//          .toJson());
//        break;
//      case FileTestsResult.MESSAGE_TYPE:
//        print(message);
//        _socket.add((new RunFileTestsRequest()
//                ..path = testfile.path
//                ..testIds.add(1))
//                .toJson());
//        break;
//    }
//  }

  void _onDone(dom.CloseEvent e) {
    _isConnected = false;
    print('Client done');
  }
}