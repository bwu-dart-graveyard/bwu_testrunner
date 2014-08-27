library bwu_testrunner.server.isolate;

import 'dart:io' as io;
import 'dart:isolate';
import 'package:unittest/unittest.dart' as ut;
import 'package:bwu_testrunner/server/unittest_configuration.dart' as utc;
import 'package:bwu_testrunner/shared/message.dart';

/**
 * Isolate implementation. When the [IsolateLauncher] launches an isolate,
 * all the main method does is to create an instance of [IsolateTestrunner].
 * All further processing is done from here.
 */
class IsolateTestrunner {

  /// The port to the [IsolateLauncher]
  final SendPort _sendPort;
  /// the reference to the main method to execute the tests.
  final Function _main;
  /// The first argument is the path of the test file.
  final List<String> _args;
  /// The port to receive messages from the main isolate ([IsolateLauncher])
  final ReceivePort receivePort = new ReceivePort();
  /// The unit test configuration used when running tests.
  utc.UnittestConfiguration _config;

  String _filePath;

  IsolateTestrunner(this._sendPort, this._main, this._args) {
    _filePath = _args[0];
    receivePort.listen(_onMessage);
    ut.groupSep = "~|~";
    _config = new utc.UnittestConfiguration(_main);
    ut.unittestConfiguration = _config;
    _sendPort.send(receivePort.sendPort);
    _config
        ..onTestProgress.listen((m) => _sendPort.send((m..path = _filePath).toJson()))
        ..onFileTestResult.listen((m) => _sendPort.send((m..path = _filePath).toJson()));
  }

  /// Dispatch incoming message processing.
  void _onMessage(String json) {
    var msg = new Message.fromJson(json);

    switch(msg.messageType) {
      case StopIsolateRequest.MESSAGE_TYPE:
        receivePort.close();
        io.exit(0);
        break;

      case TestFileRequest.MESSAGE_TYPE:
        _fileTestListRequestHandler(msg);
        break;

      case RunFileTestsRequest.MESSAGE_TYPE:
        _runFileTestsRequestHandler(msg);
        break;
    }
    //print('child isolate - message "${msg.messageType}" received: $json');
  }

  /// Handler for RunFileTestsRequest.
  /// Runs all or specified tests of the associated test file.
  void _runFileTestsRequestHandler(RunFileTestsRequest msg) {
    var response = new FileTestsResult()
        ..responseId = msg.messageId
        ..path = msg.path;

    _config.runTests(msg.testIds).then((tests) {
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
      _sendPort.send(response.toJson());
      //print('child isolate - message "${msg.messageType}" sent: ${response.toJson()}');
    });

  }

  /// Handler fro TestListRequestHandler
  /// Invokes main and retrieves test methods and groups from the unit test
  /// configuration.
  void _fileTestListRequestHandler(TestFileRequest msg) {
    var response = new ConsoleTestFile()
        ..responseId = msg.messageId
        ..path = msg.path;

    _config.getTests().then((tests) {

        tests.forEach((tc) {
          print('Test found: ${tc.description}');
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
      _sendPort.send(response.toJson());
      //print('child isolate - message "${msg.messageType}" sent: ${response.toJson()}');
    });
  }
}

