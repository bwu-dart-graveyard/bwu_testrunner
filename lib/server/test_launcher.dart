library bwu_testrunner.server.isolate_launcher;

import 'dart:async' as async;
import 'dart:collection' as coll;
import 'dart:convert' show UTF8;
import 'dart:io' as io;
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/shared/message.dart';
import 'server.dart';

class _ProcessMessageServer {
  static coll.Queue<_ProcessMessageServer> _serverQueue = new coll.DoubleLinkedQueue();
  static List<_ProcessMessageServer> _serversInUse= [];
  static coll.Queue<async.Completer<_ProcessMessageServer>> _requestQueue = new coll.DoubleLinkedQueue();
  static bool _isInitialized = false;

  static async.Future<_ProcessMessageServer> getServer() {
    if (!_isInitialized) {
      // TODO(zoechi) make number of ports and port range configurable
      for (int i = 1; i < 10; i++) {
        _serverQueue.add(new _ProcessMessageServer._(TestrunnerServer.servePort + 30 + i));
      }
      _isInitialized = true;
    }

    if(_serverQueue.isNotEmpty) {
      var s = _serverQueue.removeFirst();
      _serversInUse.add(s);
      return s._init();
    } else {
      async.Completer completer = new async.Completer();
      _requestQueue.add(completer);
      return completer.future;
    }
  }

  static void _assignServer() {
    if(_requestQueue.isNotEmpty && _serverQueue.isNotEmpty) {
      var s = _serverQueue.removeFirst();
      var r = _requestQueue.removeFirst();
      s._init()
      .then((_) => r.complete(s));
    }
  }

  io.HttpServer _server;
  //MessageSink messageHandler;
  final int port;

  /// Notifies about messages from the isolate.
  async.StreamController<Message> _onMessage;
  /// Returns a stream to allow external consumers listen to received messages.
  async.Stream get onMessage => _onMessage.stream;

  _ProcessMessageServer._(this.port);

  async.Future<_ProcessMessageServer> _init() {
    if(_onMessage != null) _onMessage.close();
    _onMessage = new async.StreamController<Message>.broadcast();
    if(_onClientConnect != null) _onClientConnect.close();
    _onClientConnect = new async.StreamController<bool>.broadcast();
    var future;
    if(_server != null) {
      future = _server.close(force: true);
    } else {
      future = new async.Future.value();
    }
    return future.then((_) {
      return io.HttpServer.bind('127.0.0.1', port)
      .then((s) {
        _server = s;
        _server.listen((request) {
          if (io.WebSocketTransformer.isUpgradeRequest(request)) {
            io.WebSocketTransformer.upgrade(request).then(_handleWebsocket);
          }
        });
        return this;
      });
    });
  }

  io.WebSocket _client;

  /// Notifies about messages from the isolate.
  async.StreamController<bool> _onClientConnect;
  /// Returns a stream to allow external consumers listen to received messages.
  async.Stream get onClientConnect => _onClientConnect.stream;

  void _handleWebsocket(io.WebSocket socket) {
    _client = socket;
    socket.listen((String s) {
      _client = socket;
      _onMessage.add(new Message.fromJson(s));
    }, onDone: () {
      _client = null;
    });
    _onClientConnect.add(true);
  }

  /// Close the server and initiate reassignment to a waiting task.
  void release() {
    if(_onMessage != null) _onMessage.close();
    if(_onClientConnect != null) _onClientConnect.close();

    var future;
    if(_server != null) {
      future = _server.close(force: true);
    } else {
      future = new async.Future.value();
    }
    future.then((_) {
      _server = null;
      _serversInUse.remove(this);
      _serverQueue.add(this);
      _assignServer();
    });
  }

  void send(Message message) {
    if(_client != null) {
      _client.add(message.toJson());
    }
  }
}

/**
 *  Launches a new isolate instance to process a single command.
 */
class _IsolateCommand {
  /// The port to receive messages of the launched isolate.
  ReceivePort _response = new ReceivePort();
  final io.File _testFile;

  /// The port to send messages to the launched isolate.
  SendPort _sendPort;

  /// Message handler of the caller.
  MessageSink _responseHandler;

  /// completed when the command execution is finished.
  async.Completer _commandCompleter;

  _IsolateCommand(this._testFile, this._responseHandler) {
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

  /// Launch a new isolate, send the request to the isolate and
  /// complete the _commandCompleter when the [StopIsolateRequest] message was
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
    var tmpMainName = path.join(io.Directory.current.path, 'tmp_bwu_testrunner_${Message.UUID.v4()}');

     main = new io.File(tmpMainName);
     main.writeAsString(_mainContent(_testFile), flush: true)
    .then((_) {
      print('Test file: ${_testFile.path}');
      var uri = Uri.parse('file://${main.absolute.path}');

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
import 'package:bwu_testrunner/server/isolate_testrunner.dart';
void main(List<String> args, SendPort replyTo) {
  new IsolateTestrunner(replyTo, tf1__.main, args);
}
''';
  }
}


/**
 *  Launches a new isolate instance to process a single command.
 */
class _ProcessCommand {
  /// The port to receive messages of the launched isolate.
  //ReceivePort _response = new ReceivePort();
  final io.File _testFile;

  /// The port to send messages to the launched isolate.
  _ProcessMessageServer _sendPort;

  /// Message handler of the caller.
  MessageSink _responseHandler;

  /// completed when the command execution is finished.
  async.Completer _commandCompleter;
  var messageList = new MessageList();

  _ProcessCommand(this._testFile, this._responseHandler);

  async.Future _initServer() {
    return _ProcessMessageServer.getServer()
    .then((server) {
      _sendPort = server;
      _sendPort.onMessage.listen((message) {
        //var message = new Message.fromJson(e);
        if (message is StopIsolateRequest) {
          //invalidateIsolate();
          //_commandCompleter.complete(true);
          //_sendPort.release();
        } else {
          messageList.messages.add(message);
          _responseHandler(message);
        }
      });
    });
  }

  /// Launch a new process, send the request to message to the isolate and
  /// complete the _commandCompleter when the StopRequestRequest message was
  /// sent by the isolate.
  async.Future processRequest(Message message) {
    _commandCompleter = new async.Completer();
    _initServer()
    .then((_) {
      _sendPort.onClientConnect.first.then((_) => _sendPort.send(message));
      _launch();
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
    io.Directory workingDir = new io.Directory(path.dirname(_testFile.path));
    var tmpMainName = path.join(workingDir.path, 'tmp_bwu_testrunner_${Message.UUID.v4()}.dart');

    main = new io.File(tmpMainName);
    main.writeAsString(_mainContent(_testFile), flush: true)
    .then((_) {
      print('Test file: ${_testFile.path}');
      var uri = Uri.parse('file://${main.absolute.path}');

      return io.Process.start('dart', ['-c', main.absolute.path, 'ws://127.0.0.1:${_sendPort.port}', _testFile.path], workingDirectory: workingDir.path)
      //return Isolate.spawnUri(uri, [_testFile.path], _response.sendPort)
      .then((process) {
        process.stderr.listen((d) => print('prc err: ${UTF8.decoder.convert(d)}'));
        process.stdout.listen((d) => print('prc: ${UTF8.decoder.convert(d)}'));
        //_isolate = isolate;
        // TODO(zoechi) not yet supported _isolate.errors.listen((e) => print('Isolate error: $e'));
        // not supported isolate.addOnExitListener(_sendPort);
        //_launchCompleter.complete(true);
        //return deleteMain(main);
        process.exitCode.then((_) {
          deleteMain(main);
          if(_sendPort != null) _sendPort.release();
          _commandCompleter.complete(true);
        });
      })
      .catchError((e) => deleteMain(main));
    })
    .then((_) {
//      return deleteMain(main)
//      .then((_) => this);
      return this;
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
import 'package:bwu_testrunner/server/process_testrunner.dart';
void main(List<String> args) {
  new ProcessTestrunner(tf1__.main, args);
}
''';
  }
}


/**
 * Manages and launches an isolates to process commands for a specific test file.
 */
class CommandLauncher {
  static const ISOLATE_COMMAND = 0;
  static const PROCESS_COMMAND = 1;

  // String stores the absolute path of the associated test file
  static final Map<String,Map<int,CommandLauncher>> _launcher = {};

  /// Create a new instance or return an existing one.
  factory CommandLauncher(io.File file, int commandType) {
    var launcherMap = _launcher[file.absolute.path];
    var launcher;
    if(launcherMap != null) {
      launcher = launcherMap[commandType];
    }
    if(launcher == null) {
      launcher = new CommandLauncher._(file, commandType);
    }
    return launcher;
  }

  /// The test file this isolate was created for.
  final io.File testFile;
  final int commandType;

  CommandLauncher._(this.testFile, this.commandType) {
    if(_launcher[testFile.absolute.path] == null) {
      _launcher[testFile.absolute.path] = {};
    }
    _launcher[testFile.absolute.path][commandType] = this;
  }

  /// Allows to invalidate an isolate for a test file without a concrete
  /// reference to the [IsolateLauncher] instance.
  static async.Future<bool> invalidate(io.File file) {
    var launcher = _launcher.remove(file.absolute.path);
    if(launcher != null) {
      launcher.forEach((k, v) {
        v.invalidateLauncher();
      });
    }
    return new async.Future.value(false);
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
        if (_isValid) {
          messageSink(message);
        }
      };
    }

    var cmd;
    switch(commandType) {
      case CommandLauncher.ISOLATE_COMMAND:
        cmd = new _IsolateCommand(testFile, messageHandler);
        break;

      case CommandLauncher.PROCESS_COMMAND:
        cmd = new _ProcessCommand(testFile, messageHandler);
        break;
    }
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

  /// Notifies about messages from the isolate.
  async.StreamController<Message> _onReceive = new async.StreamController<Message>.broadcast();
  /// Returns a stream to allow external consumers listen to received messages.
  async.Stream get onReceive => _onReceive.stream;
}
