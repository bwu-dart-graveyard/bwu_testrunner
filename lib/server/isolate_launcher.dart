library bwu_testrunner.server.isolate_launcher;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/shared/message.dart';
// import 'package:bwu_testrunner/shared/response_completer.dart';

/// Launches a new isolate instance to process a command.
class _TestCommand {
  /// The port to receive messages of the launched isolate.
  ReceivePort _response = new ReceivePort();
  final io.File _testFile;

  /// The port to send messages to the launched isolate.
  SendPort _sendPort;

  /// Message handler of the caller.
  MessageSink _responseHandler;

  /// completed when the command execution is finished.
  async.Completer _commandCompleter;

  _TestCommand(this._testFile, this._responseHandler) {
    var messageList = new MessageList();
    _response.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        print('Isolate for "${_testFile.path} launched');
        _launchCompleter.complete(this);
      } else {
        //var message = new Message.fromJson(e);
        if (message is StopIsolateRequest) {
          //invalidateIsolate();
          _commandCompleter.complete(true);
        } else {
          messageList.messages.add(message);
          _responseHandler(message);
        }
      }
    });
  }

  /// Launch a new isolate, send the request to message to the isolate and
  /// complete the _commandCompleter when the StopRequestRequest message was
  /// sent by the isolate.
  async.Future processRequest(Message message) {
    _commandCompleter = new async.Completer();
    _launch()
    .then((isolate) {
      _sendPort.send(message);
    });
    return _commandCompleter.future;
  }

  /// [_launchCompleter] completes when the isolate is ready to receive messages.
  async.Completer _launchCompleter = new async.Completer();

  /// Launches the isolate when it is not yet running.
  async.Future _launch() {
    print('Launch isolate for "${_testFile.path}');

    io.File main;
    io.Directory tmpDir;
    var tmpMainName;

    io.Directory.current.createTemp('tmp_bwu_testrunner_')
    .then((dir) {
      tmpDir = dir;
      return tmpDir.exists()
      .then((exists) {
        if(!exists) {
          throw 'Could not create a temporary directory.';
        }
        tmpMainName = '${path.basename(tmpDir.path)}_main.dart';
        main = new io.File(tmpMainName);
        return tmpDir.delete()
        .then((e) => main.writeAsString(_mainContent(_testFile), flush: true));
      });
    })
    .then((_) {
      print('Test file: ${_testFile.path}');
      var uri = Uri.parse('file://${main.absolute.path}');
      //print('uri: ${uri}');

      return Isolate.spawnUri(uri, [_testFile.path], _response.sendPort)
      .then((isolate) {
        //_isolate = isolate;
        // TODO(zoechi) not yet supported _isolate.errors.listen((e) => print('Isolate error: $e'));
        // not supported isolate.addOnExitListener(_sendPort);
        //_launchCompleter.complete(true);
      });
    })
    .then((_) {
      return deleteMain(main)
      .then((_) => this);
    })
    .catchError((e, s) {
      print('$e\n$s');
      deleteMain(main)
      .then((_) {
        //_isolateId = null;
        if(!_launchCompleter.isCompleted) {
          _launchCompleter.completeError(e);
        }
        if (_commandCompleter != null && !_commandCompleter.isCompleted) {
          _commandCompleter.completeError(e);
        }
        _commandCompleter = null;
      });
    });
    return _launchCompleter.future;
  }

  // delete temporary main
  async.Future deleteMain(io.File main) {
    return main.exists()
    .then((exists) {
      if(exists) {
        return main.delete(recursive: true);
      } else {
        return new async.Future.value();
      }
    });
  }


  /// The template for the main method used to launch the isolate.
  /// The reference to the test file is added as a library import.
  String _mainContent(io.File testFile) {
    return '''
import 'dart:isolate';

import '${testFile.absolute.path}' as tf1__;
import 'package:bwu_testrunner/server/isolate.dart';

void main(List<String> args, SendPort replyTo) {
  new IsolateTestrunner(replyTo, tf1__.main, args);
  //replyTo.send(args[0]);
  //unittestConfiguration = new utc.UnittestConfiguration();
  //print('hallo');
  //tf1__.main();
  //print('end');
}
''';
  }
}


/**
 * Launches an isolate to process a command for a specific test file.
 */
class IsolateLauncher {

  // String stores the absolute path of the associated test file
  static final Map<String,IsolateLauncher> _launcher = <String, IsolateLauncher>{};

  //final List<_TestCommand> _runningIsolates = [];
  //final MessageSink _responseHandler;

  /// Create a new instance or return an existing one.
  factory IsolateLauncher(io.File file /*, MessageSink broadcastSink*/) {
    var launcher = _launcher[file.absolute.path];
    if(launcher != null) {
      return launcher;
    } else {
      return new IsolateLauncher._(file/*, broadcastSink*/);
    }
  }

  /// The test file this isolate was created for.
  final io.File testFile;

  IsolateLauncher._(this.testFile /*, this._responseHandler*/) {
    _launcher[testFile.absolute.path] = this;
  }

//  String _isolateId;
//  String get isolateId => _isolateId;

  /// Allows to invalidate an isolate for a test file without a concrete
  /// reference to the [IsolateLauncher] instance.
  static async.Future<bool> invalidate(io.File file) {
    var launcher = _launcher.remove(file.absolute.path);
    if(launcher != null) {
      return launcher.invalidateLauncher();
    } else {
      return new async.Future.value(false);
    }
  }

  bool _isValid = true;

  void invalidateLauncher() {
    _isValid = false;
    //TODO(zoechi) ensure that a file changed message is sent to the client.
  }

  Response _testFile;

  /// Process requests sent to the isolate.
  async.Future<MessageList> processRequest(Message message, {MessageSink messageSink}) {
    if(message is TestFileRequest && _testFile != null) {
      _onReceive.add(_testFile..responseId = message.messageId);
      return new async.Future.value(true);
    }

    var messageHandler = messageSink;
    if(messageHandler == null) {
      messageHandler = _processIsolateResponse;
    } else {
      messageHandler = (Message message) {
        // ignore messages from an invalid test file isolate
        if(_isValid) {
          messageSink(message);
        }
      };
    }
    var cmd = new _TestCommand(testFile, messageHandler);
    return cmd.processRequest(message);
  }

  /// Process messages received from the isolate.
  void _processIsolateResponse(Message message) {
    // ignore messages from an invalid test file isolate
    if(_isValid) {
      if(message is ConsoleTestFile || message is HtmlTestFile) {
        _testFile = message;
      }
      _onReceive.add(message);
    }
  }

//  /// When the test file was updated or removed the isolate needs to be
//  /// stopped and launched again with the new test file.
//  /// This method only stops the isolate. The new instance is created on demand.
//  void invalidateIsolate() {
//    //var msg = new StopIsolateRequest();
//    //var future = new ResponseCompleter(msg.messageId, onReceive, timeout: new Duration(seconds: 3)).future;
//    send(new StopIsolateRequest());
//    //_isolate.kill();

//
//    if(_launchCompleter != null) {
//      if(!_launchCompleter.isCompleted) {
//        _launchCompleter.completeError(this);
//      }
//      _launchCompleter = null;
//    }
//  }

  /// Pass messages from the isolate to the clients.
  async.StreamController<Message> _onReceive = new async.StreamController<Message>.broadcast();
  /// Returns a stream to allow external consumers listen to received messages.
  async.Stream get onReceive => _onReceive.stream;
}
