library bwu_testrunner.server;

import 'dart:io' as io;
import 'testfiles.dart';
import 'package:http_server/http_server.dart' as ht;
import 'package:bwu_testrunner/server/test_launcher.dart';
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_testrunner/shared/response_forwarder.dart';
import 'package:bwu_testrunner/shared/response_collector.dart';
import 'package:bwu_testrunner/shared/response_completer.dart';

/***
 * The testrunner server implementation.
 * Accepts WebSocket connections from the client
 */
class TestrunnerServer {

  /// Contains the references to the found test files and the directory watcher.
  TestFiles testFiles;

  /// The port the server listens to websocket connect requests.
  static int servePort = 18070;

  /// The directory containing the test files.
  io.Directory testDirectory;

  TestrunnerServer(this.testDirectory, {Function onReady}) {
    testFiles = new TestFiles(testDirectory);

    io.HttpServer.bind('127.0.0.1', servePort)
    .then((server) {
      _serve(server);
      if(onReady != null) {
        onReady(servePort);
      }
    });

    testFiles.onTestFilesChanged.listen(testFilesChangedHandler);
    _initTestFilesListResponseCache();
  }

  /// Init the server
  void _serve(io.HttpServer server) {
    ht.VirtualDirectory vd = new ht.VirtualDirectory('packages/bwu_testrunner/client/content/web');
    server.listen((request) {
      if(io.WebSocketTransformer.isUpgradeRequest(request)) {
        io.WebSocketTransformer.upgrade(request).then(_handleWebsocket);
      } else {
        print("Regular ${request.method} for: ${request.uri.path}");
        if(request.uri.path == '/') {
          request.response
              ..redirect(Uri.parse('http://localhost:${servePort}/index.html'), status: io.HttpStatus.MOVED_PERMANENTLY)
              ..close();
        } else {
          vd.serveRequest(request);
        }
      }
    });
  }

  /// Connected clients.
  final _connectedClients = <io.WebSocket>[];

  /// Handle incoming connections.
  void _handleWebsocket(io.WebSocket socket) {
    print('Client connected');
    _connectedClients.add(socket);

    socket.listen((String s) {
      var c = new Message.fromJson(s);
      print('Client sent: $s');

      switch(c.messageType) {
        case TestListRequest.MESSAGE_TYPE:
          testListRequestHandler(socket, c);
          break;

        case RunFileTestsRequest.MESSAGE_TYPE:
          _runFileTestsRequestHandler(socket, c);
          break;
      }
    },
    onDone: () {
      _connectedClients.remove(socket);
      print('Client disconnected');
    });

    if(_testFilesListResponseCache != null) {
      print('connection send: ${_testFilesListResponseCache}');
      socket.add(_testFilesListResponseCache.toJson());
    }

    _runFileTestsResponseCache.forEach((k, v) {
        print('connection send: ${v}');
        socket.add(v.toJson());
    });
  }

  /// Process messages received from isolates.
  void _isolateMessageHandler(Message message) {
    if(message is StopIsolateRequest || (message is Response && message.responseId != null)) {
      ///print('ignore: ${message.toJson()}');
    } else {
      print('broadcast: ${message.toJson()}');

      _connectedClients.forEach((c) {
        c.add(message.toJson());
      });
    }
  }

  TestList _testFilesListResponseCache;

  /// Create an isolate for each found test file
  /// This method is invoked on server startup to have response data ready when
  /// the first clients connect.
  void _initTestFilesListResponseCache() {
    var testListRequest = new TestListRequest();
    _testFilesListResponseCache = new TestList();
    var consoleResponseCollector = new ResponseCollector(testListRequest);

    testFiles.consoleTestFiles.forEach((e) {
      // TODO(zoechi) remove comments to re-enable when browser-launching is fixed
      var testFileRequest = new TestFileRequest()
      ..path = e.path;
      var commandLauncher = (new CommandLauncher(e, CommandLauncher.ISOLATE_COMMAND));
      var messageSink = new StreamMessageSink();
      commandLauncher.processRequest(testFileRequest, messageSink: messageSink);
      consoleResponseCollector.addSubRequest(testFileRequest, messageSink.onMessage.first);
    });

    consoleResponseCollector.wait().then((MessageList message) {
      message.messages.forEach((ConsoleTestFile m) {
        if(m.hasTests) {
          _testFilesListResponseCache.consoleTestFiles.add(m);
        }
      });
      print(message.toJson());
    });

    var htmlResponseCollector = new ResponseCollector(testListRequest);
    testFiles.htmlTestFiles.forEach((e, f) {
//    var key = testFiles.htmlTestFiles.keys.first;
//    var value = testFiles.htmlTestFiles[key];
//    <io.File,io.File>{key: value}.forEach((e, f) {
      // TODO(zoech) handle HTML tests
      // can't be run in isolates, needs content_shell
      // response.htmlTestFiles.add(new HtmlTestFile()..path = e.path);
      var testFileRequest = new TestFileRequest()
        ..path = e.path;
      var browserLauncher = new CommandLauncher(e, CommandLauncher.BROWSER_COMMAND, f);
      var messageSink = new StreamMessageSink();
      browserLauncher.processRequest(testFileRequest, messageSink: messageSink);
      htmlResponseCollector.addSubRequest(testFileRequest, messageSink.onMessage.first);
    });

    htmlResponseCollector.wait().then((MessageList message) {
      message.messages.forEach((m) {
        if(m.hasTests) {
          _testFilesListResponseCache.htmlTestFiles.add(m);
        }
      });
      print(message.toJson());
    });

  }

  Map<String,FileTestsResult> _runFileTestsResponseCache = {};
  /***
   * Process RunFileTestsRequest.
   * A RunFileTestRequest runs all or the specified tests of one test file.
   * For each test a progress message is sent and a final response to indicate
   * that the request is finished.
   */
  void _runFileTestsRequestHandler(io.WebSocket socket,
                                  RunFileTestsRequest clientRequest) {
    bool isHtmlTest = false;
    var tf = testFiles.consoleTestFiles.where(
                (ctf) => ctf.path == clientRequest.path);
    if(tf.length == 0) {tf = testFiles.htmlTestFiles.keys.where(
            (ctf) => ctf.path == clientRequest.path);
      isHtmlTest = true;
    }
    if(tf.length == 0) {
      // TODO(zoechi) add errors to regular responses
      socket.add((new ErrorMessage()
          ..responseId = clientRequest.messageId
          ..errorMessage = 'Testfile "${clientRequest.path}" not found.').toJson());
    } else {
      var commandType;
      if(isHtmlTest) {
        commandType = CommandLauncher.BROWSER_COMMAND;
      } else {
        commandType = CommandLauncher.PROCESS_COMMAND;
      }
      var commandLauncher = new CommandLauncher(tf.first, commandType);

      var messageSink = new StreamMessageSink((message) {
        if(message is FileTestsResult) {
          return true;
        } else {
          // broadcast
          _isolateMessageHandler(message);
          return false;
        }
      });

      new ResponseForwarder(clientRequest, messageSink.onMessage,
        (FileTestsResult message) {
          socket.add(message.toJson());
          //message.r
          _runFileTestsResponseCache[clientRequest.path] = message;
        });

      commandLauncher.processRequest(clientRequest, messageSink: messageSink);
    }
  }

  // process TestListRequest
  void testListRequestHandler(io.WebSocket socket, TestListRequest clientRequest) {

    var responseCollector = new ResponseCollector(clientRequest);

    new ResponseForwarder(clientRequest, responseCollector.wait().asStream(),
        new SocketMessageSink(socket), responseCallback:
          (Request request, MessageList response) {
      TestList clientResponse = new TestList()
          ..responseId = request.messageId;

      if(response is MessageList && response.timedOut == false) {
        response.messages.forEach((Message m) {
          if(m is ConsoleTestFile) {
            if(m.hasTests) {
              clientResponse.consoleTestFiles.add(m);
            }
          } else if(m is HtmlTestFile && m.hasTests) {
            if(m.hasTests) {
              clientResponse.htmlTestFiles.add(m);
            }
          } else {
            throw 'Unsupported messagetype "${response.messageType}".';
          }
        });
        return clientResponse;
      } else {
        return response..responseId = request.messageId;
      }
    });

    testFiles.consoleTestFiles.forEach((e) {
      var commandLauncher = new CommandLauncher(e, CommandLauncher.ISOLATE_COMMAND);
      var isolateRequest = new TestFileRequest()
          ..path = e.path;
      responseCollector.addSubRequest(isolateRequest, new ResponseCompleter(isolateRequest, commandLauncher.onReceive).future);
      commandLauncher.processRequest(isolateRequest);
    });

    testFiles.htmlTestFiles.forEach((e, f) {
      // TODO(zoech) handle HTML tests
      // can't be run in isolates, needs content_shell
      // response.htmlTestFiles.add(new HtmlTestFile()..path = e.path);

      var commandLauncher = new CommandLauncher(e, CommandLauncher.BROWSER_COMMAND);
      var isolateRequest = new TestFileRequest()
        ..path = e.path;
      responseCollector.addSubRequest(isolateRequest, new ResponseCompleter(isolateRequest, commandLauncher.onReceive).future);
      commandLauncher.processRequest(isolateRequest);

    });

    responseCollector.wait();
  }

  void testFilesChangedHandler(TestFileChanged event) {
    _testFilesListResponseCache = null;
    _runFileTestsResponseCache.clear();
    _connectedClients.forEach((l) => l.add(event.toJson()));
  }
}
