library bwu_testrunner.server.isolate_testrunner;

import 'dart:async' as async;
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

  final List<async.StreamSubscription> _subscriptions = [];

  IsolateTestrunner(this._sendPort, this._main, this._args) {
    print('Isolate CWD: ${io.Directory.current}');
    _filePath = _args[0];
    _subscriptions.add(receivePort.listen(_onMessage));
    ut.groupSep = "~|~";
    _config = new utc.UnittestConfiguration(_main);
    ut.unittestConfiguration = _config;
    _sendPort.send(receivePort.sendPort);
    _subscriptions.add(_config.onTestProgress.listen((m) => _send((m..path = _filePath))));
    _subscriptions.add(_config.onFileTestResult.listen((m) => _send((m..path = _filePath))));
  }

  bool _isUsed = false;

  /// Dispatch incoming message processing.
  void _onMessage(message) {
    //var msg = new Message.fromJson(json);
    print('Isolate process message ${message}');

    switch(message.messageType) {
      case StopIsolateRequest.MESSAGE_TYPE:
        print('isolate exit');
        _exit();
        break;

      case TestFileRequest.MESSAGE_TYPE:
        print('isolate test file request start');
        _checkIsUsed();
        print('isolate test file request 1');
        _fileTestListRequestHandler(message);
        print('isolate test file request end');
        break;

      case RunFileTestsRequest.MESSAGE_TYPE:
        _checkIsUsed();
        _runFileTestsRequestHandler(message);
        print('isolate run test');
        break;
    }
  }

  /// One isolate can only execute one command (UnitTest library limitation)
  /// Return an error message on a consecutive command.
  _checkIsUsed() {
    if(_isUsed) {
      _send((new ErrorMessage()..errorMessage =
      'Isolate already used. An isolate can only execute one command.'));
      return;
    }
    _isUsed = true;
  }

  // End the isolate.
  // Currently the only proper way is to end all async processing and hope
  // that the isolate ends.
  void _exit() {
    _send(new StopIsolateRequest());
    _subscriptions.forEach((s) => s.cancel());
    _config = null;
    new async.Future(() {
      receivePort.close();
    });
//    new async.Future(() {
//      throw('Intentionally ending isolate for ${_filePath}');
//    });
  }

  /// Handler for RunFileTestsRequest.
  /// Runs all or specified tests of the associated test file.
  void _runFileTestsRequestHandler(RunFileTestsRequest msg) {
    print('Run file tests ${_filePath}');
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
      _send(response);
      _exit();
    });
  }

  /// Handler fro TestListRequestHandler
  /// Invokes main and retrieves test methods and groups from the unit test
  /// configuration.
  void _fileTestListRequestHandler(TestFileRequest msg) {
    print('fileTestListRequestHandler');
    assert(msg.messageId != null);
    assert(msg.path != null);
    var response = new ConsoleTestFile()
        ..responseId = msg.messageId
        ..path = msg.path;

    print('fileTestListRequestHandler 2');
    _config.getTests().then((tests) {

      assert(tests != null);
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
      _send(response);
      _exit();
    });
  }

  void _send(Message response) {
    print('Isolate send: $response');
    _sendPort.send(response);
  }
}

