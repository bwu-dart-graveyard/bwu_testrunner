#!/bin/dart

library bwu_testrunner.run;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:convert' show JSON;
import 'dart:convert' show UTF8;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:path/path.dart' as path;

part 'install_content_shell.dart';

// A list of possible options for Chromium can be found at http://peter.sh/experiments/chromium-command-line-switches/

final Map<String,Test>tests = {};

class Test {
  TestResult result = new TestResult();
  bool doSkipWithContentShell = false;
  bool doSkipWithPubServe = false;
  bool doSkipWithoutPubServe = false;
  List<String> contentShellOptions = [];
  String path = '';

  Test({this.contentShellOptions, this.doSkipWithContentShell, this.doSkipWithPubServe, this.doSkipWithoutPubServe, this.path}) {
    assert(contentShellOptions != null);
    assert(doSkipWithContentShell != null);
    assert(doSkipWithPubServe != null);
    assert(doSkipWithoutPubServe != null);
    assert(path != null);
  }

  Test.fromConfig(Map configData) {
    if(configData.containsKey('contentShellOptions') && configData['contentShellOptions'] != null) {
      contentShellOptions = configData['contentShellOptions'];
    }
    if(configData.containsKey('doSkipWithContentShell') && configData['doSkipWithContentShell'] != null) {
      doSkipWithContentShell = configData['doSkipWithContentShell'];
    }
    if(configData.containsKey('doSkipWithPubServe') && configData['doSkipWithPubServe'] != null) {
      doSkipWithPubServe = configData['doSkipWithPubServe'];
    }
    if(configData.containsKey('doSkipWithoutPubServe') && configData['doSkipWithoutPubServe'] != null) {
      doSkipWithPubServe = configData['doSkipWithoutPubServe'];
    }
    if(configData.containsKey('path') && configData['path'] != null) {
      path = configData['path'];
      if(!path.endsWith('/')) {
        path += '/';
      }
    }
  }
}

class TestResult {
  String name  = '';
  bool suiteFailed = false;
  int successCount = 0;
  int failCount = 0;
  bool isSkipped = false;

  @override
  String toString() {
    if(suiteFailed) {
      return '! FAIL $name Test Suite FAIL';
    } else if(isSkipped) {
      return '- SKIP $name Test Suite SKIP';
    } else {
      if(failCount != 0) {
        return '! FAIL $name $failCount FAIL, $successCount PASS (of ${successCount + failCount})';
      } else {
        return '  PASS $name (all of $successCount)';
      }
    }
  }
}

bool isPubServe = false;
int pubServePort;
String dartSdkPath;
bool isInstallContentShell = false;
io.Directory workingDir;
String configFilePath;

void main(List<String> args) {
  workingDir = io.Directory.current;
  print('current working directory: ${workingDir}');

  processArgs(args);
  loadConfigFile();

  var future = new async.Future.value();

  if(isInstallContentShell) {
    future = installContentShell();
  }

  if(isPubServe) {
    future = future.then((e) => runPubServe());
  }

  future.then((io.Process pubServe) {
    if(isPubServe) {
      pubServe.exitCode.then((ec) {
        print('pub serve ended with exit code $ec');
      });
    }

    async.Future.forEach((tests.keys), runTest)
    .then((e) {
      if(isPubServe) {
        var success = pubServe.kill(io.ProcessSignal.SIGABRT);
      }
    })
    .then((_) => printResults())
    .then((exitCode) => io.exit(exitCode));
  });
}

void processArgs(List<String> args) {
  const PORT_OPTION = 'port';
  const CONFIG_FILE_OPTION = 'config-file';
  const TEST_NAME_OPTION = 'test-name';
  const DART_SDK_PATH_OPTION = 'dart-sdk-path';
  const PACKAGE_ROOT_OPTION = 'package-root';
  const USE_PUB_SERVE_FLAG = 'pub-serve';
  const HELP_FLAG = 'help';
  const INSTALL_CONTENTSHELL_FLAG = 'install-contentshell';

  var parser = new ArgParser();

  parser.addOption(PORT_OPTION, defaultsTo: '18080', abbr: 'p',
      help: 'The port "pub serve" should serve the content on.');

  parser.addOption(CONFIG_FILE_OPTION, defaultsTo: 'test/run_config.json', abbr: 'c',
      help: 'The JSON file containing a list of tests to run and optional configuration details for each test.');

  parser.addOption(TEST_NAME_OPTION, abbr: 't', allowMultiple: true,
      help: 'When a test name is provided only this test is run.');

  parser.addOption(DART_SDK_PATH_OPTION, abbr: 'd',
      help: 'The path to the DART SDK directory.');

  parser.addOption(PACKAGE_ROOT_OPTION, abbr: 'w',
      help: 'A path to the directory of your package to tests that contains the "pubspec.yaml" file. Default is the current directory.');

  parser.addFlag(USE_PUB_SERVE_FLAG, defaultsTo: false, abbr: 's', negatable: true,
      help: 'Whether "pub serve" should be invoked to serve the tests.');

  parser.addFlag(HELP_FLAG, abbr: 'h', help: 'Print usage information.');

  parser.addFlag(INSTALL_CONTENTSHELL_FLAG, abbr: 'i', defaultsTo: true, negatable: true,
      help: 'Execute "download_contentshell.sh" script if content_shell can not be found.');

  try {
    var ar = parser.parse(args);

    if(ar[HELP_FLAG]) {
      print(parser.getUsage());
      io.exit(0);
    }

    pubServePort = int.parse(ar[PORT_OPTION]);
    isPubServe = ar[USE_PUB_SERVE_FLAG];

    if(ar.rest.length != 0) {
      print(parser.getUsage());
      io.exit(1);
    }

    configFilePath = ar[CONFIG_FILE_OPTION];

    if(ar[TEST_NAME_OPTION] != null) {
      List<String> testNames = ar[TEST_NAME_OPTION];
      if(testNames.length > 0) {
        tests.keys.forEach((testName) {
          if (testNames.contains(testName)) {
            tests[testName].doSkipWithContentShell = false;
            tests[testName].doSkipWithPubServe = false;
            tests[testName].doSkipWithoutPubServe = false;
          } else {
            tests[testName].doSkipWithContentShell = true;
          }
        });
      }
    }

    if(ar[INSTALL_CONTENTSHELL_FLAG]) {
      isInstallContentShell = true;
      if(ar[DART_SDK_PATH_OPTION] != null) {
        dartSdkPath = ar[DART_SDK_PATH_OPTION];
      } else {
        if(io.Platform.environment.containsKey('DART_SDK')) {
          dartSdkPath = io.Platform.environment['DART_SDK'];
        }
      }
    }

    if(ar[PACKAGE_ROOT_OPTION] != null) {
      workingDir = new io.Directory(ar[PACKAGE_ROOT_OPTION]);
    }

  } catch (e, s) {
    print('Parsing args threw: ${e}\n\n${s}');
    print(parser.getUsage());
    io.exit(1);
  }
}

void loadConfigFile() {
  var configFile = path.join(workingDir.path, configFilePath);
  print('Using config file "${configFile}".');
  var config = new io.File(configFile).readAsStringSync();
  var configData = JSON.decode(config);
  configData.keys.forEach((testName) {
    tests[testName] = new Test.fromConfig(configData[testName]);
  });
}

int printResults() {
  print('\n');
  tests.keys.forEach((String test) => print(tests[test].result));

  int failSuitCount = 0;
  int successCount = 0;
  int failCount = 0;
  int skippedSuitesCount = 0;

  tests.keys.forEach((test) {
    if(tests[test].result.suiteFailed) {
      failSuitCount++;
    } else {
      successCount += tests[test].result.successCount;
      failCount += tests[test].result.failCount;
    }
    if(tests[test].result.isSkipped) {
      skippedSuitesCount++;
    }
  });
  print('\===================== SUMMARY =====================');
  io.stdout.flush();
  if(failSuitCount != 0 || failCount != 0) {
    io.stderr.writeln('FAIL - Test Suite: FAIL $failSuitCount PASS ${tests.length - failSuitCount - skippedSuitesCount} (of ${tests.length}) SKIP ${skippedSuitesCount}, Test Case: FAIL $failCount PASS $successCount (of ${failCount + successCount})');
    return 1;
  } else {
    print('PASS - Suite: ${tests.length - skippedSuitesCount}, Test cases: $successCount, Suites skipped: ${skippedSuitesCount}');
    return 0;
  }
}

async.Future<io.Process> runPubServe() {
  print('launching pub serve --port $pubServePort test');
  return io.Process.start('pub', ['serve', '--port', pubServePort, 'test'], workingDirectory: workingDir.path)
  .then((p) {
    var completer = new async.Completer();

    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      toLines(text).forEach((line) {
        print('PUB | $line');
      });
      // 'Build completed' may occur more then once but complete must not be called more than once
      if(!completer.isCompleted && text.contains(new RegExp('Build completed.*'))) {
        completer.complete(p);
      }
    });
    p.stderr.listen((stdErr) {
      var text = UTF8.decoder.convert(stdErr);
      toLines(text).forEach((line) {
        io.stderr.writeln('PUB err | $line');
      });
    });
    completer.future.timeout(new Duration(seconds: 120), onTimeout: () {
      // called on timeout when future is not yet completed
      var exitCode = p.kill(io.ProcessSignal.SIGKILL);
      io.stderr.writeln('kill pub serve - succeeded: $exitCode');
      completer.completeError('pub serve launch timed out');
    });
    return completer.future;
  });
}

List<String> toLines(String text) {
  var lines = text.split('\n');
  if(lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

final PASS_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(PASS).+?.*$');
final FAIL_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(FAIL|ERROR).+?.*$');
final FAIL_TEST_SUITE_REGEX = new RegExp(r'^FAIL$');

async.Future runTest(String testName) {
  var test = tests[testName]
    ..result.name = testName;

  print('run test "$testName"');
  var url;
  if(isPubServe) {
    url = 'http://localhost:${pubServePort}/${test.path}${testName}.html';
  } else {
    url = '${testName}.html';
  }

  if(test.doSkipWithContentShell) {
    test.result.isSkipped = true;
    print('Skipping test "${testName}". Test is configured to be skipped when run in "content_shell" ');
    return null;
  }

  if(test.doSkipWithPubServe && isPubServe) {
    test.result.isSkipped = true;
    print('Skipping test "${testName}". Test is configured to be skipped when run with "pub serve" ');
    return null;
  }

  if(test.doSkipWithoutPubServe && !isPubServe) {
    test.result.isSkipped = true;
    print('Skipping test "${testName}". Test is configured to be skipped when run without "pub serve" ');
    return null;
  }

  var args = ['--dump-render-tree', '--no-sandbox']
    ..addAll(test.contentShellOptions)
    ..add(url);
  print('run "content_shell ${args.join(' ')}"');
  return io.Process.start('content_shell', args, workingDirectory: workingDir.path)
  .then((p) {
    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      toLines(text).forEach((line) {
        if(PASS_TEST_CASE_REGEX.firstMatch(line) != null) {
          test.result.suiteFailed = false;
          test.result.successCount++;
        } else if(FAIL_TEST_CASE_REGEX.firstMatch(line) != null) {
          test.result.suiteFailed = false;
          test.result.failCount++;
        } else if(FAIL_TEST_SUITE_REGEX.firstMatch(line) != null) {
          test.result.suiteFailed = true;
        }
        print('CS | $line');
      });
    });
    p.stderr.listen((stdErr) {
      var text = UTF8.decoder.convert(stdErr);
      toLines(text).forEach((line) {
        io.stderr.writeln('CS err | $line');
      });
    });
    return p.exitCode.then((ec) {
      // set suiteFailed when no result was provided
      if(test.result.failCount == 0 && test.result.successCount == 0 && test.result.suiteFailed == false) {
        test.result.suiteFailed = true;
      }
      return ec;
    });
  });
}
