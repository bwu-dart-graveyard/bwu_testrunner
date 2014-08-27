library bwu_testrunner.server.unittest_configuration;

import 'dart:async' as async;
import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/shared/message.dart';

class UnittestConfiguration extends Configuration {
  Function main;

  UnittestConfiguration(this.main) : super.blank();

  static const int _NONE = 0;
  static const int _GET_TESTS_COMMAND = 1;
  static const int _RUN_TESTS_COMMAND = 2;

  async.StreamController<TestRunProgress> _onTestRunProgress = new async.StreamController<TestRunProgress>.broadcast();

  /// Returns a stream to allow external consumers listen to TestProgress messages.
  async.Stream get onTestProgress => _onTestRunProgress.stream;

  async.StreamController<FileTestResult> _onFileTestResult = new async.StreamController<FileTestResult>.broadcast();

  /// Returns a stream to allow external consumers listen to TestProgress messages.
  async.Stream get onFileTestResult => _onFileTestResult.stream;

  /// The command currently executed
  int _command = _NONE;
  /// Completed when the command execution is done.
  async.Completer _commandCompleter;
  /// The ids of the tests to consider for the current command
  List<int> _testIds;

  /// All test cases found by getTests command.
  List<TestCase> _testCases;

  /// Returns a list of tests contained by the test file.
  /// This command is actually only executed once.
  /// Consecutive calls return the previous result.
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

  /// Execute all or specific tests of the test file.
  async.Future<List<TestCase>> runTests([List<int> testIds]) {
    _commandCompleter = new async.Completer();
    //..future.timeout(new Duration(seconds: 3),
    //    onTimeout: () => _commandCompleter.complete(_testCases));
    //_isGetTests = true;
    _command = _RUN_TESTS_COMMAND;
    _testIds = testIds == null ? [] : testIds;

    getTests()
    .then((_) => runTests());
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
    print('onStart: $testCases');
    switch (_command) {
      case _GET_TESTS_COMMAND:
        _testCases.addAll(testCases);
        //print('Tests: $_testCases');
        //testCases.forEach((tc) => disableTest(tc.id));
        break;

      case _RUN_TESTS_COMMAND:
        print('TestIds: $_testIds');
        _testCases.forEach((tc) {
          enableTest(tc.id);
        });
        //_testCases.addAll(testCases.where((tc) => _testIds.contains(tc.id)));
        print('TestCases: $testCases, ${testCases.length}');
        print('_TestCases: $_testCases, ${_testCases.length}');
        if (_testIds.length != null) {
          testCases.where((tc) => !_testIds.contains(tc.id))
          .forEach((tc) => disableTest(tc.id));
        }
        print('TestCases2: $testCases, ${testCases.length}');
        super.onInit();
        break;
    }
  }

  @override
  void onTestStart(TestCase testCase) {
    print('onTestStart');
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        _onTestRunProgress.
        add(new TestRunProgress()
          ..testId = testCase.id
          ..status = TestRunProgress.STARTED);
        super.onTestStart(testCase);
        break;
    }
  }

  @override
  void onTestResult(TestCase testCase) {
    print('onTestResult');
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        super.onTestResult(testCase);
        _onTestRunProgress.add(new TestRunProgress()
          ..testId = testCase.id
          ..status = TestRunProgress.RESULT
          ..result = testCase.result);
        break;
    }
    // TODO(zoechi) send progress notification to client
  }

  @override
  void onTestResultChanged(TestCase testCase) {
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
  void onLogMessage(TestCase testCase, String message) {
    print('onMessage');
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        super.onLogMessage(testCase, message);
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
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        super.onDone(success);
        _onTestRunProgress.add(new TestRunProgress()
          ..status = TestRunProgress.RESULT_UPDATE);
        break;
    }
  }

  @override
  void onSummary(int passed, int failed, int errors, List<TestCase> results,
                 String uncaughtError) {
    print('onSummary');
    switch (_command) {
      case _RUN_TESTS_COMMAND:
        super.onSummary(passed, failed, errors, results, uncaughtError);
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
