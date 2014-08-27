part of bwu_testrunner.shared.message;

/**
 * Request a list of all test files including a list of all tests in each file.
 */
class TestListRequest extends Message {

  static const MESSAGE_TYPE = 'TestListRequest';
  String get messageType => MESSAGE_TYPE;

  TestListRequest() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
  }

  @override
  Map toMap() {
    return super.toMap();
  }
}

/**
 * Response to TestListRequest.
 * The message passes a ConsoleTestFile or HtmlTestFile instance for each
 * found test file.
 */
class TestList extends Message {

  static const MESSAGE_TYPE = 'TestList';
  String get messageType => MESSAGE_TYPE;

  TestList() : super.protected();

  final List<ConsoleTestFile> consoleTestFiles = <ConsoleTestFile>[];
  final List<HtmlTestFile> htmlTestFiles = <HtmlTestFile>[];

  @override
  void fromMap(Map map) {
    consoleTestFiles.addAll(
        map['consoleTestfiles'].map((e) => new Message.createFromMap(e)));
    htmlTestFiles.addAll(
        map['htmlTestfiles'].map((e) => new Message.createFromMap(e)));
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['consoleTestfiles'] = consoleTestFiles.map((e) => e.toMap()).toList()
        ..['htmlTestfiles'] = htmlTestFiles.map((e) => e.toMap()).toList();
  }
}

/**
 * Request a list of tests for a specific file.
 */
class TestFileRequest extends Message {

  static const MESSAGE_TYPE = 'FileTestListRequest';
  String get messageType => MESSAGE_TYPE;

  String path;

  TestFileRequest() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
  }

  @override
  Map toMap() {
    return super.toMap()..['path'] = path;
  }
}


//class FileTestList extends Message {
//
//  static const MESSAGE_TYPE = 'FileTestList';
//  String get messageType => MESSAGE_TYPE;
//
//
//  String path;
//
//  FileTestList() : super.protected();
//
//  @override
//  void fromMap(Map map) {
//    super.fromMap(map);
//    path = map['path'];
//  }
//
//  @override
//  Map toMap() {
//    return super.toMap()..['path'] = path;
//  }
//}

/// The response to a TestFileRequest with details about the tests found in that file.
class ConsoleTestFile extends Message {

  static const MESSAGE_TYPE = 'ConsoleTestFile';
  String get messageType => MESSAGE_TYPE;

  String path;
  final List<TestGroup> groups = [];
  final List<Test> tests = [];

  ConsoleTestFile() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    groups.addAll(map['groups'].map((g) => new Message.createFromMap(g)));
    tests.addAll(map['tests'].map((t) => new Message.createFromMap(t)));
    path = map['path'];
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['path'] = path
        ..['groups'] = groups.map((g) => g.toMap()).toList()
        ..['tests'] = tests.map((t) => t.toMap()).toList();
  }
}

/// The response to a TestFileRequest with details about the tests found in that file.
class HtmlTestFile extends Message {

  static const MESSAGE_TYPE = 'HtmlTestFile';
  String get messageType => MESSAGE_TYPE;

  String path;

  HtmlTestFile() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
  }

  @override
  Map toMap() {
    return super.toMap()..['path'] = path;
  }
}

/// Details about a test in a test file.
class Test extends Message {

  static const MESSAGE_TYPE = 'Test';
  String get messageType => MESSAGE_TYPE;

  String name;
  int id;

  Test() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    name = map['name'];
    id = map['id'];
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['name'] = name
        ..['id'] = id;
  }
}

/// Details about a group of tests in a test file.
class TestGroup extends Message {

  static const MESSAGE_TYPE = 'TestGroup';
  String get messageType => MESSAGE_TYPE;

  String name;

  final List<TestGroup> groups = <TestGroup>[];
  final List<Test> tests = <Test>[];

  TestGroup() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    groups.addAll(map['groups'].map((g) => new Message.createFromMap(g)));
    tests.addAll(map['tests'].map((t) => new Message.createFromMap(t)));
    name = map['name'];
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['name'] = name
        ..['groups'] = groups.map((g) => g.toMap()).toList()
        ..['tests'] = tests.map((t) => t.toMap()).toList();
  }
}

/**
 * A request to execute all or specific tests of a test file.
 * The test file is specified by [path]. If [testIds] contains values
 * only the tests with these ids are executed.
 */
class RunFileTestsRequest extends Message {
  static const MESSAGE_TYPE = 'RunFileTestsRequest';
  String get messageType => MESSAGE_TYPE;

  String path;
  final List<int> testIds = <int>[];

  RunFileTestsRequest() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
    testIds.addAll(map['testIds']);
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['path'] = path
        ..['testIds'] = testIds.toList();
  }
}

/// The response to RunFileTestsRequest which passes a list of TestResult
/// where a TestResult is the result of a single test.
class FileTestsResult extends Message {

  static const MESSAGE_TYPE = 'FileTestsResult';
  String get messageType => MESSAGE_TYPE;

  String path;
  final List<TestResult> testResults = [];

  FileTestsResult() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
    testResults.addAll(
        map['testResults'].map((tr) => new Message.createFromMap(tr)));
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['path'] = path
        ..['testResults'] = testResults.map((tr) => tr.toMap()).toList();
  }
}

/// Contains the results of an executed test.
class TestResult extends Message {

  static const MESSAGE_TYPE = 'TestResult';
  String get messageType => MESSAGE_TYPE;

  int id;
  bool isComplete;
  String message;
  bool passed;
  String result;
  Duration runningTime;
  String stackTrace;
  DateTime startTime;

  TestResult() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    id = map['id'];
    isComplete = map['isComplete'];
    message = map['message'];
    passed = map['passed'];
    result = map['result'];
    runningTime = map['runningTime'] == null ? null : new Duration(microseconds: map['runningTime']);
    stackTrace = map['stackTrace'];
    startTime = map['startTime'] == null ? null : new DateTime.fromMillisecondsSinceEpoch(map['startTime']);
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['id'] = id
        ..['isComplete'] = isComplete
        ..['message'] = message
        ..['passed'] = passed
        ..['result'] = result
        ..['runningTime'] = runningTime == null ? null : runningTime.inMicroseconds
        ..['stackTrace'] = stackTrace
        ..['startTime'] = startTime == null ? null : startTime.millisecondsSinceEpoch;
  }
}

/// A request for the isolate to stop itself.
class StopIsolateRequest extends Message {
  static const MESSAGE_TYPE = 'StopIsolateRequest';
  String get messageType => MESSAGE_TYPE;

  StopIsolateRequest() : super.protected();
}

/// Notification about add/remove/edit of a test file.
class TestFileChanged extends Message {

  static const MESSAGE_TYPE = 'TestFileChanged';
  String get messageType => MESSAGE_TYPE;

  String path;
  String changeType;

  TestFileChanged() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
    changeType = map['changeType'];
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['path'] = path
        ..['changeType'] = changeType;
  }
}

/// Notification about the progress of the test execution.
class TestRunProgress extends Message {
  static const NONE = 0;
  static const STARTED = 1;
  static const RESULT_UPDATE = 2;
  static const RESULT = 3;
  static const LOG_MESSAGE = 4;
  static const DONE = 5;

  static const MESSAGE_TYPE = 'TestRunProgress';
  String get messageType => MESSAGE_TYPE;

  String path;
  int testId;
  int status;
  String result;
  String logMessage;
  bool isSuccess;

  TestRunProgress() : super.protected();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
    testId = map['testId'];
    status = map['status'];
    logMessage = map['logMessage'];
    result = map['result'];
  }

  @override
  Map toMap() {
    return super.toMap()
      ..['path'] = path
      ..['testId'] = testId
      ..['status'] = status
      ..['result'] = result
      ..['logMessage'] = logMessage;
  }
}

/// Notification about an error.
class Timeout extends ErrorMessage {

  static const MESSAGE_TYPE = 'Timeout';
  String get messageType => MESSAGE_TYPE;

  Timeout() : super() {
    errorId = 1;
    errorMessage = 'The response to the request didn\'t arrive in time.';
  }
}
