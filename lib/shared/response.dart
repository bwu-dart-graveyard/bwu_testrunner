library bwu_testrunner.shared.response;

import 'message.dart';

class TestList extends Message {

  static const MESSAGE_TYPE = 'TestList';

  TestList() : super.protected();

  @override
  void fromMap(Map map) {
    consoleTestfiles.addAll(
        map['consoleTestfiles'].map((e) => new Message.createFromMap(e)));
    htmlTestfiles.addAll(
        map['htmlTestfiles'].map((e) => new Message.createFromMap(e)));
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['consoleTestfiles'] = consoleTestfiles.map((e) => e.toMap()).toList()
        ..['htmlTestfiles'] = htmlTestfiles.map((e) => e.toMap()).toList();
  }

  final List<ConsoleTestFile> consoleTestfiles = <ConsoleTestFile>[];
  final List<HtmlTestFile> htmlTestfiles = <HtmlTestFile>[];
}

class ConsoleTestFile extends Message {

  static const MESSAGE_TYPE = 'ConsoleTestFile';

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

class HtmlTestFile extends Message {

  static const MESSAGE_TYPE = 'HtmlTestFile';

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

class FileTestList extends Message {

  static const MESSAGE_TYPE = 'FileTestList';

  String path;

  FileTestList() : super.protected();

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

class Test extends Message {

  static const MESSAGE_TYPE = 'Test';

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

class TestGroup extends Message {

  static const MESSAGE_TYPE = 'TestGroup';

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

class FileTestsResult extends Message {

  static const MESSAGE_TYPE = 'FileTestsResult';

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

class TestResult extends Message {

  static const MESSAGE_TYPE = 'TestResult';

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
    runningTime = new Duration(microseconds: map['runningTime']);
    stackTrace = map['stackTrace'];
    startTime = new DateTime.fromMillisecondsSinceEpoch(map['startTime']);
  }

  @override
  Map toMap() {
    return super.toMap()
        ..['id'] = id
        ..['isComplete'] = isComplete
        ..['message'] = message
        ..['passed'] = passed
        ..['result'] = result
        ..['runningTime'] = runningTime.inMicroseconds
        ..['stackTrace'] = stackTrace
        ..['startTime'] = startTime.millisecondsSinceEpoch;
  }
}


class TestFileChanged extends Message {

  static const MESSAGE_TYPE = 'TestFileChanged';

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

class Timeout extends Message {

  static const MESSAGE_TYPE = 'Timeout';

  Timeout() : super.protected();
}

//class Dummy extends Message {
//
//  static const MESSAGE_TYPE = 'Dummy';
//
//  Dummy() : super.protected();
//}

class MessageList extends Message {

  static const MESSAGE_TYPE = 'MessageList';

  MessageList() : super.protected();

  final List<Message> messages = [];

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

