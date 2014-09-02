library bwu_testrunner.shared.message;

import 'dart:async' as async;
import 'dart:convert' show JSON;
import 'package:uuid/uuid.dart' show Uuid;

abstract class Message {
  static Uuid UUID = new Uuid();
  static const MESSAGE_TYPE = 'Message';

  Message() {
    messageId = UUID.v4();
  }

  factory Message.fromJson(String json) {
    return new Message.createFromMap(JSON.decode(json));
  }

  factory Message.createFromMap(Map map) {
    switch(map['messageType']) {
      case TestListRequest.MESSAGE_TYPE:
        return new TestListRequest()..fromMap(map);
      case TestList.MESSAGE_TYPE:
        return new TestList()..fromMap(map);
      case TestFileRequest.MESSAGE_TYPE:
        return new TestFileRequest()..fromMap(map);
      //case FileTestList.MESSAGE_TYPE:
        //return new FileTestList()..fromMap(map);
      case ConsoleTestFile.MESSAGE_TYPE:
        return new ConsoleTestFile()..fromMap(map);
      case HtmlTestFile.MESSAGE_TYPE:
        return new HtmlTestFile()..fromMap(map);
      case TestGroup.MESSAGE_TYPE:
        return new TestGroup()..fromMap(map);
      case Test.MESSAGE_TYPE:
        return new Test()..fromMap(map);
      case RunFileTestsRequest.MESSAGE_TYPE:
        return new RunFileTestsRequest()..fromMap(map);
      case FileTestsResult.MESSAGE_TYPE:
        return new FileTestsResult()..fromMap(map);
      case TestResult.MESSAGE_TYPE:
        return new TestResult()..fromMap(map);
      case TestRunProgress.MESSAGE_TYPE:
        return new TestRunProgress()..fromMap(map);
      case TestFileChanged.MESSAGE_TYPE:
        return new TestFileChanged()..fromMap(map);
      case MessageList.MESSAGE_TYPE:
        return new MessageList()..fromMap(map);
//      case Timeout.MESSAGE_TYPE:
//        return new Timeout()..fromMap(map);
      case ErrorMessage.MESSAGE_TYPE:
        return new ErrorMessage()..fromMap(map);
      case StopIsolateRequest.MESSAGE_TYPE:
        return new StopIsolateRequest()..fromMap(map);
      default:
        throw 'Message type "${map['messageType']}" is unknown.';
    }
  }

  String get messageType => throw '"messageType" must be overridden in derived classes.';
  String messageId;

  void fromMap(Map map) {
    messageId = map['messageId'];
  }

  Map toMap() {
    return {
      'messageType' : messageType,
      'messageId' : messageId
    };
  }

  String toJson() {
    return JSON.encode(toMap());
  }

  @override
  String toString() => toJson();

  @override
  bool operator ==(Request other) {
    assert(other is Request);
    return other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}

/// A Message that expects an answer.
abstract class Request extends Message {
  Response timedOutResponse();
}

/// Normally sent as a response to a request.
abstract class Response extends Message {
  String responseId;
  bool timedOut = false;

  void fromMap(Map map) {
    super.fromMap(map);
    responseId = map['responseId'];
    timedOut = map['timedOut'];
  }

  Map toMap() {
    return super.toMap()
        ..['responseId'] = responseId
        ..['timedOut'] = timedOut;
  }
}

typedef void MessageSink(Message message);

typedef bool MessageFilter(Message message);

class StreamMessageSink extends Function {
  async.StreamController<Message> _ctrl = new async.StreamController();
  async.Stream<Message> get onMessage => _ctrl.stream;

  Function _filter;
  StreamMessageSink([this._filter]);

  call(Message message) {
    if(_filter == null || _filter(message)) {
      _ctrl.add(message);
    }
  }
}

class ErrorMessage extends Response {

  static const MESSAGE_TYPE = 'ErrorMessage';
  String get messageType => MESSAGE_TYPE;

  ErrorMessage() : super();

  int errorId = 0;
  String errorMessage;
  String stackTrace;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    errorId = map['errorId'];
    errorMessage = map['errorMessage'];
    stackTrace = map['stackTrace'];
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['errorId'] = errorId
        ..['errorMessage'] = errorMessage
        ..['stackTrace'] = stackTrace;
  }
}

/// A generic class to send a collection of messages.
class MessageList<T extends Message> extends Response {

  static const MESSAGE_TYPE = 'MessageList';
  String get messageType => MESSAGE_TYPE;

  MessageList() : super();

  final List<T> messages = [];

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    messages.addAll(
        map['messages'].map((m) => new Message.createFromMap(m)));

  }

  @override
  Map toMap() {
    return super.toMap()
        ..['messages'] = messages.map((tr) => tr.toMap()).toList();
  }
}

/**
 * Request a list of all test files including a list of all tests in each file.
 */
class TestListRequest extends Request {

  static const MESSAGE_TYPE = 'TestListRequest';
  String get messageType => MESSAGE_TYPE;

  TestListRequest() : super();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
  }

  @override
  Map toMap() {
    return super.toMap();
  }

  @override
  TestList timedOutResponse() {
    return new TestList()
        ..timedOut = true;
  }
}

/**
 * Response to TestListRequest.
 * The message passes a ConsoleTestFile or HtmlTestFile instance for each
 * found test file.
 */
class TestList extends Response {

  static const MESSAGE_TYPE = 'TestList';
  String get messageType => MESSAGE_TYPE;

  TestList() : super();

  final List<ConsoleTestFile> consoleTestFiles = <ConsoleTestFile>[];
  final List<HtmlTestFile> htmlTestFiles = <HtmlTestFile>[];

  @override
  void fromMap(Map map) {
    super.fromMap(map);
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
class TestFileRequest extends Request {

  static const MESSAGE_TYPE = 'FileTestListRequest';
  String get messageType => MESSAGE_TYPE;

  String path;

  TestFileRequest() : super();

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map['path'];
  }

  @override
  Map toMap() {
    return super.toMap()..['path'] = path;
  }

  @override
  TestFile timedOutResponse() {
    return new TestFile()
        ..responseId = messageId
        ..timedOut = true;
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

// A common base class for console and HTML test files.
// A concrete instance of this type must only be used for a TimeOut response.
class TestFile extends Response {
  static const MESSAGE_TYPE = 'TestFile';
}

/// The response to a TestFileRequest with details about the tests found in that file.
class ConsoleTestFile extends TestFile {

  static const MESSAGE_TYPE = 'ConsoleTestFile';
  String get messageType => MESSAGE_TYPE;

  String path;
  final List<TestGroup> groups = [];
  final List<Test> tests = [];

  ConsoleTestFile() : super();

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
class HtmlTestFile extends TestFile {

  static const MESSAGE_TYPE = 'HtmlTestFile';
  String get messageType => MESSAGE_TYPE;

  String path;

  HtmlTestFile() : super();

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

  Test() : super();

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

  TestGroup() : super();

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
class RunFileTestsRequest extends Request {
  static const MESSAGE_TYPE = 'RunFileTestsRequest';
  String get messageType => MESSAGE_TYPE;

  String path;
  final List<int> testIds = <int>[];

  RunFileTestsRequest() : super();

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

  @override
  FileTestsResult timedOutResponse() {
    return new FileTestsResult()
        ..responseId = messageId
        ..timedOut = true
        ..path = path;
  }
}

/// The response to RunFileTestsRequest which passes a list of TestResult
/// where a TestResult is the result of a single test.
class FileTestsResult extends Response {

  static const MESSAGE_TYPE = 'FileTestsResult';
  String get messageType => MESSAGE_TYPE;

  String path;
  final List<TestResult> testResults = [];

  FileTestsResult() : super();

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

  TestResult() : super();

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

  StopIsolateRequest() : super();
}

/// Notification about add/remove/edit of a test file.
class TestFileChanged extends Message {

  static const MESSAGE_TYPE = 'TestFileChanged';
  String get messageType => MESSAGE_TYPE;

  String path;
  String changeType;

  TestFileChanged() : super();

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
class TestRunProgress extends Response {
  static const NONE = 0;
  static const STARTED = 1;
  static const RESULT = 2;
  static const RESULT_UPDATE = 3;
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

  TestRunProgress() : super();

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
//class Timeout extends ErrorMessage {
//
//  static const MESSAGE_TYPE = 'Timeout';
//  String get messageType => MESSAGE_TYPE;
//
//  Timeout() : super() {
//    errorId = 1;
//    errorMessage = 'The response to the request didn\'t arrive in time.';
//  }
//}
