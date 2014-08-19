library bwu_testrunner.server.isolate;

import 'dart:isolate';
import 'package:unittest/unittest.dart' as ut;
import 'package:bwu_testrunner/server/unittest_configuration.dart' as utc;
import 'package:bwu_testrunner/shared/message.dart';

// Isolate implementation
class IsolateTestrunner {

  final SendPort sendPort;
  Function main;
  List<String> args;
  ReceivePort receivePort = new ReceivePort();
  utc.UnittestConfiguration config;

  IsolateTestrunner(this.sendPort, this.main, this.args) {
    receivePort.listen(onMessage);
    ut.groupSep = "~|~";
    config = new utc.UnittestConfiguration(main);
    ut.unittestConfiguration = config;
    sendPort.send(receivePort.sendPort);
  }

  void onMessage(String json) {
    var msg = new Message.fromJson(json);
    switch(msg.messageType) {
      case FileTestListRequest.MESSAGE_TYPE:
        fileTestListRequestHandler(msg);
        break;

      case RunFileTestsRequest.MESSAGE_TYPE:
        runFileTestsRequestHandler(msg);
        break;
    }
    //print('child isolate - message "${msg.messageType}" received: $json');
  }

  void runFileTestsRequestHandler(RunFileTestsRequest msg) {
    var response = new FileTestsResult()
        ..responseId = msg.messageId
        ..path = msg.path;

    config.runTests(msg.testIds).then((tests) {
      tests.forEach((tc) {
        print('TestResult: $tc');
        if(tc.startTime == null) {
          print('starttime is null');
        }
      response.testResults.add(new TestResult()
          ..id = tc.id
          ..isComplete = tc.isComplete
          ..message = tc.message
          ..passed = tc.passed
          ..result = tc.result
          ..runningTime = tc.runningTime == null ? new Duration(milliseconds: 0) : tc.runningTime
          ..stackTrace = tc.stackTrace.toString()
          ..startTime = tc.startTime == null ? new DateTime.fromMillisecondsSinceEpoch(0) : tc.startTime);
      });
      sendPort.send(response.toJson());
    });

  }

  void fileTestListRequestHandler(FileTestListRequest msg) {
    var response = new ConsoleTestFile()
        ..responseId = msg.messageId
        ..path = msg.path;

    config.getTests().then((tests) {

        tests.forEach((tc) {
          var names = tc.description.split(ut.groupSep);
          var test = new Test()
              ..name = names.last
              ..id = tc.id;
          if(names.length > 1) {
            TestGroup root;
            TestGroup parentGroup;
            while(names.length > 1) {
              var tmpGroup = new TestGroup()..name = names[0];
              names.removeAt(0);
              if(root == null) {
                root = tmpGroup;
                var found = response.groups.where((g) => g.name == tmpGroup.name);
                if(found.isEmpty) {
                  parentGroup = root;
                  response.groups.add(root);
                } else {
                  root = found.first;
                  parentGroup = root;
                }
              } else {
                var found = parentGroup.groups.where((g) => g.name == tmpGroup.name);
                if(found.isEmpty) {
                  parentGroup.groups.add(tmpGroup);
                  parentGroup = tmpGroup;
                } else {
                  parentGroup = found.first;
                }
              }
            }
            parentGroup.tests.add(test);
          } else {
            response.tests.add(test);
          }
        });
      sendPort.send(response.toJson());
    });
  }
}

