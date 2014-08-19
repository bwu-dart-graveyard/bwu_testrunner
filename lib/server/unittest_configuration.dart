library bwu_testrunner.server.unittest_configuration;

import 'package:unittest/unittest.dart';
import 'dart:async' as async;

class UnittestConfiguration extends Configuration {
  Function main;
  UnittestConfiguration(this.main) : super.blank();

  static const int _NONE = 0;
  static const int _GET_TESTS_COMMAND = 1;
  static const int _RUN_TESTS_COMMAND = 2;

  //bool _isGetTests = false;

  int _command = _NONE;
  async.Completer _commandCompleter;
  List<int> _testIds;

  List<TestCase> _testCases;

  async.Future<List<TestCase>> getTests() {
    if(_testCases != null) {
      return new async.Future.value(_testCases.toList());
    }
    _commandCompleter = new async.Completer()
    ..future.timeout(new Duration(seconds: 3),
        onTimeout: () => _commandCompleter.complete(_testCases));
    _command = _GET_TESTS_COMMAND;
    _testCases = [];
    main();
    return _commandCompleter.future;
  }

  async.Future<List<TestCase>> runTests(List<int> testIds) {
    _commandCompleter = new async.Completer();
    //..future.timeout(new Duration(seconds: 3),
    //    onTimeout: () => _commandCompleter.complete(_testCases));
    //_isGetTests = true;
    _command = _RUN_TESTS_COMMAND;
    _testCases = [];
    _testIds = testIds;
    main();
    return _commandCompleter.future;
  }

  @override
  bool get autoStart => true;

  @override
  void onInit() {
    super.onInit();
    //print('onInit');
    //print(testCases);
  }

  @override
  void onStart() {
    //print('onStart: $testCases');
    switch(_command) {
      case _GET_TESTS_COMMAND:
        _testCases.addAll(testCases);
        //print('Tests: $_testCases');
        testCases.forEach((tc) => disableTest(tc.id));
        break;

      case _RUN_TESTS_COMMAND:
        print('TestIds: $_testIds');
        _testCases.addAll(testCases.where((tc) => _testIds.contains(tc.id)));
        print('TestCases: $testCases, ${testCases.length}');
        print('_TestCases: $_testCases, ${_testCases.length}');
        testCases.where((tc) => !_testIds.contains(tc.id))
        .forEach((tc) => disableTest(tc.id));
        print('TestCases2: $testCases, ${testCases.length}');
    }
    super.onInit();
  }

  @override
  void onTestStart(TestCase testCase) {
    print('onTestStart');
    super.onTestStart(testCase);
  }

  @override
  void onTestResult(TestCase testCase) {
    print('onTestResult');
    super.onTestResult(testCase);
    // TODO(zoechi) send progress notification to client
  }

  @override
  void onTestResultChanged(TestCase testCase) {
    print('onTestResultChanged');
    super.onTestResultChanged(testCase);
  }

  @override
  void onLogMessage(TestCase testCase, String message) {
    print('onMessage');
  }

//  @override
//  void onExpectFailure(String reason) {
//    print('onExpectFailure');
//    super.onExpectFailure(reason);
//  }

//  @override
//  String formatResult(TestCase testCase) {
//    print('formatResult');
//    return super.formatResult(testCase);
//  }

  @override
  void onDone(bool success) {
    //print('onDone');
    super.onDone(success);
  }

  @override
  void onSummary(int passed, int failed, int errors, List<TestCase> results,
        String uncaughtError) {
    //print('onSummary');
    super.onSummary(passed, failed, errors, results, uncaughtError);
    if(_commandCompleter != null) {
      _commandCompleter.complete(_testCases);
      _commandCompleter = null;
      _command = _NONE;
    }
  }
}