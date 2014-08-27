library bwu_testrunner.server.isolate_launcher;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_testrunner/shared/response_completer.dart';

/**
 * Launches isolates for one specified test file.
 */
class IsolateLauncher {

  // String stores the absolute path of the associated test file
  static final Map<String,IsolateLauncher> _isolates = <String, IsolateLauncher>{};

  /// Create a new instance or return an existing one.
  factory IsolateLauncher(io.File file, MessageSink broadcastSink) {
    var launcher = _isolates[file.absolute.path];
    if(launcher != null) {
      return launcher;
    } else {
      return new IsolateLauncher._(file, broadcastSink);
    }
  }

  /// The test file this isolate was created for.
  final io.File testFile;
  final MessageSink _broadcastSink;

  IsolateLauncher._(this.testFile, this._broadcastSink) {
    _isolates[testFile.absolute.path] = this;
  }

  String _isolateId;
  String get isolateId => _isolateId;

  /// Allows to invalidate an isolate for a test file without a concrete
  /// reference to the [IsolateLauncher] instance.
  static async.Future<bool> invalidate(io.File file) {
    var launcher = _isolates.remove(file.absolute.path);
    if(launcher != null) {
      return launcher.invalidateIsolate();
    } else {
      return new async.Future.value(false);
    }
  }

  /// When the test file was updated or removed the isolate needs to be
  /// stopped and launched again with the new test file.
  /// This method only stops the isolate. The new instance is created on demand.
  void invalidateIsolate() {
    //var msg = new StopIsolateRequest();
    //var future = new ResponseCompleter(msg.messageId, onReceive, timeout: new Duration(seconds: 3)).future;
    send(new StopIsolateRequest());
  }

  /// Handle notifications of received messages.
  async.StreamController<Message> _onReceive = new async.StreamController<Message>.broadcast();
  /// Returns a stream to allow external consumers listen to received messages.
  async.Stream get onReceive => _onReceive.stream;

  /// The port to receive messages of the launched isolate.
  ReceivePort _response = new ReceivePort();

  /// The port to send messages to the launched isolate.
  SendPort _sendPort;

  /// Sends a message to the isolate.
  void send(Message message) {
    if(!isRunning) {
      throw 'Isolate for file "${testFile.path}" is not running.';
    }
    _sendPort.send(message.toJson());
  }

  /// Returns true when the isolate is running.
  bool get isRunning => _launchCompleter != null;
  async.Completer _launchCompleter;

  /// Launches the isolate when it is not yet running.
  async.Future<IsolateLauncher> _launch() {
    if(isRunning) {
      if(!_launchCompleter.isCompleted) {
        return _launchCompleter.future;
      }
      return new async.Future.value(this);
    }
    _launchCompleter = new async.Completer();
    _isolateId = Message.UUID.v4().toString();

    print('Launch isolate for "${testFile.path}');

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
        .then((e) => main.writeAsString(_mainContent(testFile), flush: true));
      });
    })
    .then((_) {
      print('Test file: ${testFile.path}');
      var uri = Uri.parse('file://${main.absolute.path}');
      //print('uri: ${uri}');

      return Isolate.spawnUri(uri, [testFile.path], _response.sendPort)
      .then((i) {
        _response.listen((e) {
          if(e is SendPort) {
            _sendPort = e;
            print('Isolate for "${testFile.path} launched');
            _launchCompleter.complete(this);
          } else {
            _onReceive.add(new Message.fromJson(e)); // TODO(zoechi) remove
            _broadcastSink(new Message.fromJson(e));
          }
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
          _launchCompleter = null;
          _isolateId = null;
          _launchCompleter.completeError(e);
        });

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
