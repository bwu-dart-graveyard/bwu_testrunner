library bwu_testrunner.server.isolate_launcher;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/shared/message.dart';

class IsolateLauncher {

  static final Map<String,IsolateLauncher> _isolates = <String, IsolateLauncher>{};

  factory IsolateLauncher(io.File file) {
    var launcher = _isolates[file.absolute.path];
    if(launcher != null) {
      return launcher;
    } else {
      return new IsolateLauncher._(file);
    }
  }

  final io.File testFile;
  IsolateLauncher._(this.testFile) {
    _isolates[testFile.absolute.path] = this;
  }

  async.StreamController<Message> _onReceive = new async.StreamController<Message>.broadcast();
  async.Stream get onReceive => _onReceive.stream;

  ReceivePort response = new ReceivePort();
  SendPort sendPort;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  void send(Message message) {
    if(!isRunning) {
      throw 'Isolate for file "${testFile.path}" is not running.';
    }
    sendPort.send(message.toJson());
  }

  async.Completer _launchCompleter;

  async.Future<IsolateLauncher> launch() {
    if(isRunning) {
      return new async.Future.value(this);
    }
    _launchCompleter = new async.Completer();
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
        .then((e) => main.writeAsString(mainContent(testFile), flush: true));
      });
    })
    .then((_) {
      print('Test file: ${testFile.path}');
      var uri = Uri.parse('file://${main.absolute.path}');
      //print('uri: ${uri}');

      return Isolate.spawnUri(uri, ['foo'], response.sendPort)
      .then((i) {
        _isRunning = true;
        response.listen((e) {
          if(e is SendPort) {
            sendPort = e;
            _launchCompleter.complete(this);
          } else {
            _onReceive.add(new Message.fromJson(e));
          }
        });
      })
      .then((_) {
        return deleteMain(main)
        .then((_) => this);
      })
      .catchError((e, s) {
        _isRunning = false;
        print('$e\n$s');
        return deleteMain(main)
        .then(throw e);
      });
    });
    return _launchCompleter.future;
  }

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

  String mainContent(io.File testFile) {
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