library bwu_testrunner.server.main;

//import 'dart:async' as async;
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/server/server.dart';
//import 'package:bwu_testrunner/shared/message.dart';

TestrunnerServer server;

void main() {
  if(path.basename(io.Directory.current.path) == 'bin') {
    io.Directory.current = io.Directory.current.parent;
  }
  print('WD: ${io.Directory.current.absolute.path}');

  server = new TestrunnerServer(new io.Directory('test'), onReady: testClient);
}

io.WebSocket socket;

void testClient(int port) {
  return;
//  print('server ready');
//  io.WebSocket.connect('ws://localhost:${port}')
//  .then((s) {
//    socket = s;
//    s.listen(onData, onDone: onDone);
//    s.add(new TestListRequest().toJson());
//  });
}

//var testfile;
//
//void onData(String json) {
//  var message = new Message.fromJson(json);
//  print('Client: ${message.toJson()}');
//  switch(message.messageType) {
//    case TestList.MESSAGE_TYPE:
//      testfile = message.consoleTestfiles.firstWhere((e) =>
//          e.path == 'test/console_launcher/src/group_with_one_failing_test.dart');
//      socket.add((new RunFileTestsRequest()
//        ..path = testfile.path
//        ..testIds.add(1))
//        .toJson());
//      break;
//    case FileTestsResult.MESSAGE_TYPE:
//      print(message);
//      socket.add((new RunFileTestsRequest()
//              ..path = testfile.path
//              ..testIds.add(1))
//              .toJson());
//      break;
//  }
//}

void onDone() {
  print('Client done');
}
