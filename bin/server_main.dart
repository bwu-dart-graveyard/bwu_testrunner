library bwu_testrunner.server.main;

import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/server/server.dart';
import 'package:bwu_testrunner/server/logging_handler.dart' as lh;
import 'package:logging/logging.dart' as logging;

final _logger = new logging.Logger('bwu_testrunner.server.main');

TestrunnerServer server;

void main() {
  lh.LogPrintHandler.initLogging();

  if(path.basename(io.Directory.current.path) == 'bin') {
    io.Directory.current = io.Directory.current.parent;
  }
  print('WD: ${io.Directory.current.absolute.path}');

  server = new TestrunnerServer(new io.Directory('test'), onReady: onReady);
}

void onReady(int port) {
  print('The BWU Testrunner server is listening on "http://localhost:${port}" for connections.');
}
