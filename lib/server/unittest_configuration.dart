library bwu_testrunner.server.unittest_configuration;

import 'dart:async' as async;
import 'package:unittest/unittest.dart' as ut;
import 'package:bwu_testrunner/shared/message.dart';

class UnittestConfiguration extends ut.Configuration {
  Function main;

  UnittestConfiguration(this.main) : super.blank();

  static const int _NONE = 0;
  static const int _GET_TESTS_COMMAND = 1;
  static const int _RUN_TESTS_COMMAND = 2;

  async.StreamController<TestRunProgress> _onTestRunProgress = new async.StreamController<TestRunProgress>.broadcast();

  /// Returns a stream to allow external consumers listen to TestProgress messages.
  async.Stream get onTestProgress => _onTestRunProgress.stream;

  async.StreamController<FileTestsResult> _onFileTestResult = new async.StreamController<FileTestsResult>.broadcast();

  /// Returns a stream to allow external consumers listen to TestProgress messages.
  async.Stream get onFileTestResult => _onFileTestResult.stream;

  /// The command currently executed
  int _command = _NONE;

  /// Completed when the command execution is done.
  async.Completer _commandCompleter;

  /// The ids of the tests to consider for the current command
  List<int> _testIds;

  /// All test cases found by getTests command.
  List<ut.TestCase> _testCases = [];

  /// Returns a list of tests contained by the test file.
  /// This command is actually only executed once.
  /// Consecutive calls return the previous result.
  async.Future<List<ut.TestCase>> getTests() {
    _commandCompleter = new async.Completer()
      ..future.timeout(new Duration(seconds: 3),
    onTimeout: () => _commandCompleter.complete(_testCases));
    _command = _GET_TESTS_COMMAND;
    main();
    return _commandCompleter.future;
  }

  /// Execute all or specific tests of the test file.
  async.Future<List<ut.TestCase>> runTests([List<int> testIds]) {
    _commandCompleter = new async.Completer();
    //..future.timeout(new Duration(seconds: 3),
    //    onTimeout: () => _commandCompleter.complete(_testCases));
    //_isGetTests = true;

    //getTests()
  //.then((_) {
//      ut.ensureInitialized();
      _command = _RUN_TESTS_COMMAND;
      _testIds = testIds == null ? _testCases.map((tc) => tc.id).toList() : testIds;
  //    ut.runTests();
    //});
    main();
    return _commandCompleter.future;
  }

  @override
  bool get autoStart => true;

  @override
  void onInit() {
    super.onInit();
    print('onInit - cmd: ${_command}');
    //print(testCases);
  }

  @override
  void onStart() {
    print('onStart: ${ut.testCases}');
    _testCases.addAll(ut.testCases);
    switch (_command) {
    case _GET_TESTS_COMMAND:
        //print('Tests: $_testCases');
        ut.testCases.forEach((tc) => ut.disableTest(tc.id));
        break;

      case _RUN_TESTS_COMMAND:
        print('TestIds: $_testIds');
        if (_testIds.length != 0) {
          ut.testCases.where((tc) => !_testIds.contains(tc.id))
          .forEach((tc) => ut.disableTest(tc.id));
        }
        print('TestCases2: ${ut.testCases}, ${ut.testCases.length}');
        break;
    }
    super.onInit();
  }

  @override
  void onTestStart(ut.TestCase testCase) {
    print('onTestStart');
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        _onTestRunProgress.
        add(new TestRunProgress()
          ..testId = testCase.id
          ..status = TestRunProgress.STARTED);
        break;
    }
    super.onTestStart(testCase);
  }

  @override
  void onTestResult(ut.TestCase testCase) {
    print('onTestResult');
    super.onTestResult(testCase);
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        _onTestRunProgress.add(new TestRunProgress()
          ..testId = testCase.id
          ..status = TestRunProgress.RESULT
          ..result = testCase.result);
        break;
    }
    // TODO(zoechi) send progress notification to client
  }

  @override
  void onTestResultChanged(ut.TestCase testCase) {
    print('onTestResultChanged');
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        super.onTestResultChanged(testCase);
        _onTestRunProgress.add(new TestRunProgress()
          ..testId = testCase.id
          ..status = TestRunProgress.RESULT_UPDATE);
        break;
    }
  }

  @override
  void onLogMessage(ut.TestCase testCase, String message) {
    print('onMessage');
    super.onLogMessage(testCase, message);
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        _onTestRunProgress.add(new TestRunProgress()
          ..testId = testCase.id
          ..logMessage = message
          ..status = TestRunProgress.RESULT_UPDATE);
        break;
    }
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
    print('onDone');
    super.onDone(success);
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        _onTestRunProgress.add(new TestRunProgress()
          ..status = TestRunProgress.RESULT_UPDATE);
        break;
    }
  }

  @override
  void onSummary(int passed, int failed, int errors, List<ut.TestCase> results,
                 String uncaughtError) {
    print('onSummary - cmd: ${_command}');
    super.onSummary(passed, failed, errors, results, uncaughtError);
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        var msg = new FileTestsResult();
        results.forEach((tc) {
          msg.testResults.add(new TestResult()
            ..id = tc.id
            ..isComplete = tc.isComplete
            ..message = tc.message
            ..passed = tc.passed
            ..result = tc.result
            ..runningTime = tc.runningTime
            ..stackTrace = tc.stackTrace.toString()
            ..startTime = tc.startTime);
        });
        _onFileTestResult.add(msg);
        break;
    }

    if (_commandCompleter != null) {
      _commandCompleter.complete(_testCases);
      _commandCompleter = null;
      _command = _NONE;
    }
  }
}
