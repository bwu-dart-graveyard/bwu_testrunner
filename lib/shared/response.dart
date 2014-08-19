library bwu_testrunner.shared.response;

import 'message.dart';

class TestList extends Message {

  static const MESSAGE_TYPE = 'TestList';

  TestList() : super.protected();

  @override
  void fromMap(Map map) {
    consoleTestfiles.addAll(
        map['consoleTestfiles'].map((e) => new Message.fromJson(e)));
    htmlTestfiles.addAll(
        map['htmlTestfiles'].map((e) => new Message.fromJson(e)));
  }

  @override
  Map toMap() {
    var json = super.toMap();
    json['consoleTestfiles'] = consoleTestfiles.map((e) => e.toJson()).toList();
    json['htmlTestfiles'] = htmlTestfiles.map((e) => e.toJson()).toList();
    return json;
  }

  final consoleTestfiles = <ConsoleTestFile>[];
  final htmlTestfiles = <HtmlTestFile>[];
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
    groups.addAll(map['groups'].map((g) => new Message.fromJson(g)));
    tests.addAll(map['tests'].map((t) => new Message.fromJson(t)));
    path = map['path'];
  }

  @override
  Map toMap() {
    var json = super.toMap();
    json['path'] = path;
    json['groups'] = groups.map((g) => g.toJson()).toList();
    json['tests'] = tests.map((t) => t.toJson()).toList();
    return json;
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
    var json = super.toMap();
    json['path'] = path;
    return json;
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
    var json = super.toMap();
    json['path'] = path;
    return json;
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
    var json = super.toMap();
    json['name'] = name;
    json['id'] = id;
    return json;
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
    groups.addAll(map['groups'].map((g) => new Message.fromJson(g)));
    tests.addAll(map['tests'].map((t) => new Message.fromJson(t)));
    name = map['name'];
  }

  @override
  Map toMap() {
    var json = super.toMap();
    json['name'] = name;
    json['groups'] = groups.map((g) => g.toJson()).toList();
    json['tests'] = tests.map((t) => t.toJson()).toList();
    return json;
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
    testResults.addAll(map['testResults'].map((tr) => new Message.fromJson(tr)));
  }

  @override
  Map toMap() {
    var json = super.toMap();
    json['path'] = path;
    json['testResults'] = testResults.map((tr) => tr.toJson()).toList();
    return json;
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
    var json = super.toMap();
    json['id'] = id;
    json['isComplete'] = isComplete;
    json['message'] = message;
    json['passed'] = passed;
    json['result'] = result;
    json['runningTime'] = runningTime.inMicroseconds;
    json['stackTrace'] = stackTrace;
    json['startTime'] = startTime.millisecondsSinceEpoch;
    return json;
  }
}

