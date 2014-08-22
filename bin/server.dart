library bwu_testrunner.server.main;

import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:bwu_testrunner/server/server.dart';

TestrunnerServer server;

void main() {
  if(path.basename(io.Directory.current.path) == 'bin') {
    io.Directory.current = io.Directory.current.parent;
  }
  print('WD: ${io.Directory.current.absolute.path}');

  server = new TestrunnerServer(new io.Directory('test'), onReady: startClient);
}

void startClient(int port) {
  print('The BWU Testrunner server is listening on "http://localhost:${port}" for connections.');
}
