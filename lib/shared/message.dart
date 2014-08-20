library bwu_testrunner.shared.command;

import 'dart:io' as io;
import 'dart:convert' show JSON;
import 'package:uuid/uuid.dart' show Uuid;
import 'package:bwu_testrunner/shared/request.dart';
import 'package:bwu_testrunner/shared/response.dart';

export 'package:bwu_testrunner/shared/request.dart';
export 'package:bwu_testrunner/shared/response.dart';

abstract class Message {
  static Uuid UUID = new Uuid();

  Message.protected() {
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
      case FileTestListRequest.MESSAGE_TYPE:
        return new FileTestListRequest()..fromMap(map);
      case FileTestList.MESSAGE_TYPE:
        return new FileTestList()..fromMap(map);
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
      case TestFileChanged.MESSAGE_TYPE:
        return new TestFileChanged()..fromMap(map);
      case Timeout.MESSAGE_TYPE:
        return new Timeout()..fromMap(map);
      default:
        throw 'Message type "${map['messageType']}" is unknown.';
    }
  }

  String get messageType => runtimeType.toString();
  String messageId;
  String responseId;
  io.WebSocket socket;

  void fromMap(Map map) {
    messageId = map['messageId'];
    responseId = map['responseId'];
  }

  Map toMap() {
    return {
      'messageType' : messageType,
      'messageId' : messageId,
      'responseId' : responseId
    };
  }

  String toJson() {
    return JSON.encode(toMap());
  }
}

abstract class MessageSink {
  void send(Message message);
}
