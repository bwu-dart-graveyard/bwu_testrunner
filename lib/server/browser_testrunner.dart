library bwu_testrunner.server.browser_testrunner;

import 'dart:async' as async;
import 'dart:html' as dom;
import 'dart:js' as js;
import 'package:unittest/unittest.dart' as ut;
import 'package:bwu_testrunner/server/unittest_configuration.dart' as utc;
import 'package:bwu_testrunner/shared/message.dart';

/**
 * Process implementation. When the [ProcessLauncher] launches a process,
 * all the main method does is to create an instance of [ProcessTestrunner].
 * All further processing is done from here.
 */
class BrowserTestrunner {

  // TODO(zoechi) add timeout for tests running to long

  /// The port to the [ProcessLauncher]
  /* final SendPort _sendPort; */
  /// the reference to the main method to execute the tests.
  final Function _main;
  /// The first argument is the path of the test file.
  //final List<String> _args;
  /// The port to receive messages from the main isolate ([ProcessLauncher])
  //final ReceivePort receivePort = new ReceivePort();
  /// The unit test configuration used when running tests.
  utc.UnittestConfiguration _config;

  String _filePath;
  String _serverUrl;

  final List<async.StreamSubscription> _subscriptions = [];

  BrowserTestrunner(this._main /*, this._args*/) {
    var uri = Uri.parse(dom.window.location.toString());
    print('uri: ${uri}');
    //print('args: ${_args}');
    _serverUrl = 'ws://${uri.queryParameters['host']}:${uri.queryParameters['port']}';
    _filePath = uri.queryParameters['file'];
//    print('Process CWD: ${io.Directory.current}');
    ut.groupSep = "~|~";
    _config = new utc.UnittestConfiguration(_main);
    ut.unittestConfiguration = _config;
    _subscriptions.add(_config.onTestProgress.listen((m) => _send((m..path = _filePath))));
    _subscriptions.add(_config.onFileTestResult.listen((m) => _send((m..path = _filePath))));
    _subscriptions.add(dom.window.onError.listen((e) {
      // Some tests may expect this and have no way to suppress the error.
      if (js.context['testExpectsGlobalError'] != true) {
        ut.handleExternalError(e, '(DOM callback has errors)');
      }
    }));
    _subscriptions.add(dom.window.onMessage.listen((e) {
      if ('unittest-suite-external-error' == e.data) {
        ut.handleExternalError('<unknown>', '(external error detected)');
      }
    }));

    _connect();
  }

  dom.WebSocket _socket;

  /// Connect to the server.
  async.Future<bool> _connect() {
    var completer = new async.Completer();
    print('ServerUrl: ${_serverUrl}');
    _socket = new dom.WebSocket(_serverUrl)
      ..onMessage.listen((dom.MessageEvent e) {
        print('Process received: ${e}');
        _onMessage(new Message.fromJson(e.data));
      })
      //..done.then((_) => _exit());
      //..onClose.listen(_onDone)
      ..onError.listen(print)
      ..onOpen.first.then((_) {
        print('Connected');
        completer.complete(true);
      });

    return completer.future;
  }

  bool _isUsed = false;

  /// Dispatch incoming message processing.
  void _onMessage(message) {
    //var msg = new Message.fromJson(json);
    print('Process process message ${message}');

    switch(message.messageType) {
      case StopIsolateRequest.MESSAGE_TYPE:
        _exit();
        break;

      case TestFileRequest.MESSAGE_TYPE:
        _checkIsUsed();
        dom.window.postMessage('unittest-suite-wait-for-done', '*');
        _fileTestListRequestHandler(message);
        break;

      case RunFileTestsRequest.MESSAGE_TYPE:
        _checkIsUsed();
        dom.window.postMessage('unittest-suite-wait-for-done', '*');
        _runFileTestsRequestHandler(message);
        break;
    }
    //print('child process - message "${msg.messageType}" received: $json');
  }

  /// One isolate can only execute one command (UnitTest library limitation)
  /// Return an error message on a consecutive command.
  _checkIsUsed() {
    if(_isUsed) {
      _send((new ErrorMessage()..errorMessage =
      'Process already used. An process can only execute one command.'));
      return;
    }
    _isUsed = true;
  }

  // Exit the process.
  void _exit() {
    print('exiting browser process');
    _send(new StopIsolateRequest());
    _subscriptions.forEach((s) => s.cancel());
    _config = null;
    new async.Future(() {
      _socket.close();
      dom.window.postMessage('unittest-suite-done', '*');
      //io.exit(0);
      //receivePort.close();
    });
//    new async.Future(() {
//      throw('Intentionally ending process for ${_filePath}');
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
    var response = new HtmlTestFile()
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
      _send(response);
      _exit();
    });
  }

  void _send(Message response) {
    print('Process send: $response');
    _socket.send(response.toJson());
  }
}

