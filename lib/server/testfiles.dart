library bwu_testrunner.server.testfiles;

import 'dart:async' as async;
import 'dart:io' as io;
import 'package:path/path.dart' as path;

class TestFiles {

  static final scriptFileRegexp = new RegExp(r'''(?:.*<script .*?src=(["']))([a-zA-Z0-9\._-]*?.dart)(?:\1>.*)''');
  static final mainWithUnitTest = new RegExp(r'''(?:[\s\S]*import\s(["']))(package:unittest/unittest.dart\1)(?:[\s\S])+?(void main\(|main\()(?:[\s\S])+''');

  final io.Directory testDirectory;

  final consoleTestfiles = <io.File>[];
  final htmlTestfiles = <io.File, io.File>{};

  final async.StreamController _onTestfilesChanged = new async.StreamController.broadcast();
  async.Stream get onTestfilesChanged => _onTestfilesChanged.stream;

  final directoryWatches = <async.StreamSubscription>[];

  TestFiles(this.testDirectory) {
    print('watch ${testDirectory.absolute.path}');
    directoryWatches.add(testDirectory.watch(recursive: true).listen(_testFilesChangedHandler));
    testDirectory.listSync(recursive: true, followLinks: false)
    .where((e) => e is io.Directory)
    .forEach((e) => directoryWatches.add(e.watch().listen(_testFilesChangedHandler)));
    findTestFiles();
  }

  void _testFilesChangedHandler(io.FileSystemEvent e) {
    // TODO(zoechi) listen/stop listening for added/deleted directories
    print('testfiles changed');
    findTestFiles();
    _onTestfilesChanged.add(null);
  }

  void findTestFiles() {
    consoleTestfiles.clear();
    htmlTestfiles.clear();

    Map htmlTestfilesPath = {};

    var files = testDirectory.listSync(recursive: true, followLinks: false);
    files.where((f) => f is io.File && path.extension(f.path) == '.html').forEach((f) {
      var match = scriptFileRegexp.firstMatch(f.readAsStringSync());
      var scriptName = match.group(2);
      //scriptName = scriptName.substring(scriptName.length - 1);
      if(match != null) {
        //print('Found script file name "${scriptName}" in "${f.path}".');
        var scriptFile = new io.File(path.join(path.dirname(f.path), scriptName));
        //print('"${scriptFile.path}" exists: ${scriptFile.existsSync()}');
        if(mainWithUnitTest.firstMatch(scriptFile.readAsStringSync()) != null) {
          //print('"${scriptFile.path}" imports "package:unittest/unittest.dart" and has a "main" method.');
          //print('Add "${scriptFile.path}" to HTML tests (associated with "${f.path}".');
          htmlTestfiles[scriptFile]=f;
          htmlTestfilesPath[scriptFile.absolute.path] = 1;
          print('Html: ${f.path}');
        }
      }
    });
    files.where((f) => f is io.File && path.extension(f.path) == '.dart' && !htmlTestfilesPath.containsKey(f.absolute.path))
    .forEach((f) {
      if(mainWithUnitTest.firstMatch(f.readAsStringSync()) != null) {
        //print('"${f.path}" imports "package:unittest/unittest.dart" and has a "main" method.');
        //print('Add "${f.path}" to console tests.');
        consoleTestfiles.add(f);
        print('Console: ${f.path}');
      }
    });
  }
}