library bwu_testrunner.shared.request;

import 'message.dart';

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
 * Request a list of tests for a specific file.
 */
class FileTestListRequest extends Message {

  static const MESSAGE_TYPE = 'FileTestListRequest';
  String get messageType => MESSAGE_TYPE;

  String path;

  FileTestListRequest() : super.protected();

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

class StopIsolateRequest extends Message {
  static const MESSAGE_TYPE = 'StopIsolateRequest';
  String get messageType => MESSAGE_TYPE;

  StopIsolateRequest() : super.protected();
}

