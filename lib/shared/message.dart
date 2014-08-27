library bwu_testrunner.shared.message;

import 'dart:convert' show JSON;
import 'package:uuid/uuid.dart' show Uuid;

part 'package:bwu_testrunner/shared/request_response.dart';

abstract class Message {
  static Uuid UUID = new Uuid();
  static const MESSAGE_TYPE = 'Message';

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
      case Timeout.MESSAGE_TYPE:
        return new Timeout()..fromMap(map);
      case ErrorMessage.MESSAGE_TYPE:
        return new ErrorMessage()..fromMap(map);
      default:
        throw 'Message type "${map['messageType']}" is unknown.';
    }
  }

  String get messageType => throw '"messageType" must be overridden in derived classes.';
  String messageId;
  String responseId;

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

  @override
  String toString() => toJson();
}

typedef void MessageSink(Message message);
/// interface for class that can be passed to ResponseCompleter as message receiver.
//abstract class MessageSink {
//  void send(Message message);
//}

class ErrorMessage extends Message {

  static const MESSAGE_TYPE = 'ErrorMessage';
  String get messageType => MESSAGE_TYPE;

  ErrorMessage() : super.protected();

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
class MessageList<T extends Message> extends Message {

  static const MESSAGE_TYPE = 'MessageList';
  String get messageType => MESSAGE_TYPE;

  MessageList() : super.protected();

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
