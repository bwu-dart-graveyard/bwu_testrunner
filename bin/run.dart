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

final Map<String, Test> tests = {};

class Test {
  Map<TestType, TestResult> results = <TestType, TestResult>{
    TestType.FILE: new TestResult(TestType.FILE),
    TestType.PUB_SERVE: new TestResult(TestType.PUB_SERVE)
  };
  bool skipContentShellTest = false;
  bool skipPubServeTest = false;
  bool skipFileTest = false;
  List<String> contentShellOptions = [];
  String path = '';

  Test({this.contentShellOptions, this.skipContentShellTest,
      this.skipPubServeTest, this.skipFileTest, this.path}) {
    assert(contentShellOptions != null);
    assert(skipContentShellTest != null);
    assert(skipPubServeTest != null);
    assert(skipFileTest != null);
    assert(path != null);
  }

  Test.fromConfig(Map configData) {
    if (configData.containsKey('contentShellOptions') &&
        configData['contentShellOptions'] != null) {
      contentShellOptions = configData['contentShellOptions'];
    }
    if (configData.containsKey('skipContentShellTest') &&
        configData['skipContentShellTest'] != null) {
      skipContentShellTest = configData['skipContentShellTest'];
    }
    if (configData.containsKey('skipPubServeTest') &&
        configData['skipPubServeTest'] != null) {
      skipPubServeTest = configData['skipPubServeTest'];
    }
    if (configData.containsKey('skipFileTest') &&
        configData['skipFileTest'] != null) {
      skipPubServeTest = configData['skipFileTest'];
    }
    if (configData.containsKey('path') && configData['path'] != null) {
      path = configData['path'];
    }
  }
}

class TestType {
  static const PUB_SERVE = const TestType._(1);
  static const FILE = const TestType._(2);

  static get values => const [PUB_SERVE, FILE];

  final int value;

  const TestType._(this.value);
}

class TestResult {
  String name = '';
  bool suiteFailed = false;
  int successCount = 0;
  int failCount = 0;
  bool isSkipped = false;
  TestType testType;
  TestResult(this.testType);

  @override
  String toString() {
    if (suiteFailed) {
      return '! FAIL $name Test Suite FAIL';
    } else if (isSkipped) {
      return '- SKIP $name Test Suite SKIP';
    } else {
      if (failCount != 0) {
        return
            '! FAIL $name $failCount FAIL, $successCount PASS (of ${successCount + failCount})';
      } else {
        return '  PASS $name (all of $successCount)';
      }
    }
  }
}

bool runPubServeTests = true;
bool runFileTests = true;
int pubServePort;
String dartSdkPath;
bool isInstallContentShell = false;
io.Directory workingDir;
String configFilePath;

void main(List<String> args) {
  workingDir = io.Directory.current;
  print('current working directory: ${workingDir}');
  contentShellPath = 'content_shell';
  contentShellDownloadPath = workingDir.absolute.path;

  processArgs(args);

  loadConfigFile();

  var future = new async.Future.value();

  if (isInstallContentShell) {
    io.Directory.current = contentShellDownloadPath;
    print('Download content_shell archive to "${contentShellDownloadPath}');

    future = future.then((e) => installContentShell()).then((e) {
      io.Directory.current = workingDir;
    });
  }

  io.Process pubServe;
  if (runPubServeTests) {
    future = future.then((e) => runPubServe()).then((p) {
      pubServe = p;
      p.exitCode.then((ec) {
        print('pub serve ended with exit code $ec');
      });
    });
  }

  //var testsToRun = <async.Future>[];
  future.then((e) {
    var nextTestFuture = new async.Future.value();
    TestType.values.forEach((testType) {
      tests.keys.forEach(
          (testName) =>
              nextTestFuture = nextTestFuture.then(
                  (e) => new async.Future(() => runTest(testName, testType))));
    });
    //return async.Future.wait(testsToRun);
    return nextTestFuture;
  }).then((e) {
    if (runPubServeTests) {
      return pubServe.kill(io.ProcessSignal.SIGABRT);
    }
  }).then((_) => printResults()).then((exitCode) {
    io.Directory.current = workingDir;
    io.exit(exitCode);
  });
}

void fail(int exitCode, [String message]) {
  if (message != null) {
    io.stderr.writeln(message);
  }
  io.Directory.current = workingDir;
  io.exit(exitCode);
}

void processArgs(List<String> args) {
  const PORT_OPTION = 'port';
  const CONFIG_FILE_OPTION = 'config-file';
  const TEST_NAME_OPTION = 'test-name';
  const DART_SDK_PATH_OPTION = 'dart-sdk-path';
//  const WORKING_DIR_OPTION = 'package-root';
  const CONTENT_SHELL_PATH_OPTION = 'contentshell-path';
  const CONTENT_SHELL_DOWNLOAD_PATH_OPTION = 'contentshell-download-path';

  const NO_PUB_SERVE_FLAG = 'no-pub-serve';
  const NO_FILE_FLAG = 'no-file';
  const HELP_FLAG = 'help';
  const INSTALL_CONTENTSHELL_FLAG = 'install-contentshell';

  var parser = new ArgParser();

  parser.addOption(
      PORT_OPTION,
      defaultsTo: '18080',
      abbr: 'p',
      help: 'The port "pub serve" should serve the content on.');

  parser.addOption(
      CONFIG_FILE_OPTION,
      defaultsTo: 'test/run_config.json',
      abbr: 'c',
      help:
          'The JSON file containing a list of tests to run and optional configuration details for each test.');

  parser.addOption(
      TEST_NAME_OPTION,
      abbr: 't',
      allowMultiple: true,
      help:
          'When a test name is provided only this test is run. This option can be added more than once');

  parser.addOption(
      DART_SDK_PATH_OPTION,
      abbr: 'd',
      help: 'The path to the DART SDK directory.');

//  parser.addOption(WORKING_DIR_OPTION, abbr: 'w',
//      help: 'A path to the directory of your package to tests that contains the "pubspec.yaml" file. Default is the current directory.');

  parser.addOption(
      CONTENT_SHELL_PATH_OPTION,
      abbr: 'o',
      help: 'The path of the "content_shell" executable.');

  parser.addOption(
      CONTENT_SHELL_DOWNLOAD_PATH_OPTION,
      abbr: 'n',
      help:
          'The path of the "content_shell" download archive should be downloaded and extracted to.');

  parser.addFlag(
      NO_PUB_SERVE_FLAG,
      defaultsTo: true,
      negatable: false,
      abbr: 's',
      help: 'Don\'t run tests with "pub serve".');

  parser.addFlag(
      NO_FILE_FLAG,
      defaultsTo: true,
      negatable: false,
      abbr: 'f',
      help: 'Don\'t run tests from files.');

  parser.addFlag(
      HELP_FLAG,
      abbr: 'h',
      help: 'Print usage information.',
      negatable: false);

  parser.addFlag(
      INSTALL_CONTENTSHELL_FLAG,
      abbr: 'i',
      defaultsTo: false,
      negatable: false,
      help:
          'Execute "download_contentshell.sh" script if content_shell can not be found.');

  try {
    var ar = parser.parse(args);

    if (ar[HELP_FLAG]) {
      print(parser.getUsage());
      io.Directory.current = workingDir;
      io.exit(0);
    }

    pubServePort = int.parse(ar[PORT_OPTION]);
    runPubServeTests = ar[NO_PUB_SERVE_FLAG];
    runFileTests = ar[NO_FILE_FLAG];

    if (ar.rest.length != 0) {
      print(parser.getUsage());
      fail(1);
    }

    configFilePath = ar[CONFIG_FILE_OPTION];

    if (ar[TEST_NAME_OPTION] != null) {
      List<String> testNames = ar[TEST_NAME_OPTION];
      if (testNames.length > 0) {
        tests.keys.forEach((testName) {
          if (testNames.contains(testName)) {
            tests[testName].skipContentShellTest = false;
            tests[testName].skipPubServeTest = false;
            tests[testName].skipFileTest = false;
          } else {
            tests[testName].skipContentShellTest = true;
          }
        });
      }
    }

    if (ar[INSTALL_CONTENTSHELL_FLAG]) {
      isInstallContentShell = true;
      if (ar[DART_SDK_PATH_OPTION] != null) {
        dartSdkPath = ar[DART_SDK_PATH_OPTION];
      } else {
        if (io.Platform.environment.containsKey('DART_SDK')) {
          dartSdkPath = io.Platform.environment['DART_SDK'];
        }
      }
    }

//    if(ar[WORKING_DIR_OPTION] != null) {
//      workingDir = new io.Directory(ar[WORKING_DIR_OPTION]);
//      io.Directory.current = workingDir;
//      print('Changed current working directory to : ${workingDir}');
//    }

    if (ar[CONTENT_SHELL_PATH_OPTION] != null) {
      contentShellPath = path.join(
          workingDir.absolute.path,
          ar[CONTENT_SHELL_PATH_OPTION]);
    }

    if (ar[CONTENT_SHELL_DOWNLOAD_PATH_OPTION] != null) {
      contentShellDownloadPath = path.join(
          workingDir.absolute.path,
          ar[CONTENT_SHELL_DOWNLOAD_PATH_OPTION]);
    }

  } catch (e, s) {
    print('Parsing args threw: ${e}\n\n${s}');
    print(parser.getUsage());
    fail(1);
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

  int globalFailSuitCount = 0;
  int globalSuccessCount = 0;
  int globalFailCount = 0;
  int globalSkippedSuitesCount = 0;

  bool isFail = false;

  TestType.values.forEach((testType) {
    int failSuitCount = 0;
    int successCount = 0;
    int failCount = 0;
    int skippedSuitesCount = 0;

    switch (testType) {
      case TestType.FILE:
        if (runFileTests) {
          print('\n------------------- File tests --------------------');
          tests.keys.forEach(
              (String test) => print(tests[test].results[TestType.FILE]));
        } else {
          print('\n--------------- File tests skipped ----------------');
        }
        break;

      case TestType.PUB_SERVE:
        if (runPubServeTests) {
          print('\n----------------- Pub serve tests -----------------');
          tests.keys.forEach(
              (String test) => print(tests[test].results[TestType.FILE]));
        } else {
          print('\n------------- Pub serve tests skipped -------------');
        }
        break;

      default:
        fail(1, '\nUnsupported test type: ${testType}.');
    }

    tests.keys.forEach((test) {
      if (tests[test].results[testType].suiteFailed) {
        failSuitCount++;
      } else {
        successCount += tests[test].results[testType].successCount;
        failCount += tests[test].results[testType].failCount;
      }
      if (tests[test].results[testType].isSkipped) {
        skippedSuitesCount++;
      }
    });

    print('\n===================== SUMMARY =====================');
    io.stdout.flush();
    if (failSuitCount != 0 || failCount != 0) {
      io.stderr.writeln(
          'FAIL - Test Suite: FAIL $failSuitCount PASS ${tests.length - failSuitCount - skippedSuitesCount} (of ${tests.length}) SKIP ${skippedSuitesCount}, Test Case: FAIL $failCount PASS $successCount (of ${failCount + successCount})');
      isFail = true;
    } else {
      print(
          'PASS - Suite: ${tests.length - skippedSuitesCount}, Test cases: $successCount, Suites skipped: ${skippedSuitesCount}');
    }
  });

  if (isFail) {
    return 1;
  } else {
    return 0;
  }
}

async.Future<io.Process> runPubServe() {
  print('launching pub serve --port $pubServePort test');
  return io.Process.start(
      'pub',
      ['serve', '--port', pubServePort.toString(), 'test'],
      workingDirectory: workingDir.path).then((p) {
    var completer = new async.Completer();

    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      toLines(text).forEach((line) {
        print('PUB | $line');
      });


          // 'Build completed' may occur more then once but complete must not be called more than once
      if (!completer.isCompleted &&
          text.contains(new RegExp('Build completed.*'))) {
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
  if (lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

final PASS_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(PASS).+?.*$');
final FAIL_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(FAIL|ERROR).+?.*$');
final FAIL_TEST_SUITE_REGEX = new RegExp(r'^FAIL$');

async.Future runTest(String testName, TestType testType) {
  var test = tests[testName]..results[testType].name = testName;

  var url;
  switch (testType) {
    case TestType.PUB_SERVE:
      url =
          'http://localhost:${pubServePort}/${path.join(test.path, '${testName}.html')}';
      break;
    case TestType.FILE:
      url = path.join('test', test.path, '${testName}.html');
      break;
    default:
      throw 'Unsupported test type: ${testType}.';
  }

  if (test.skipContentShellTest) {
    test.results[testType].isSkipped = true;
    print(
        'Skipping test "${testName}". Test is configured to be skipped when run in "content_shell" ');
    return null;
  }

  switch (testType) {
    case TestType.PUB_SERVE:
      if (test.skipPubServeTest) {
        test.results[testType].isSkipped = true;
        print(
            'Skipping test "${testName}". Test is configured to be skipped when run with "pub serve" ');
        return null;
      }
      break;

    case TestType.FILE:
      if (test.skipFileTest) {
        test.results[testType].isSkipped = true;
        print(
            'Skipping test "${testName}". Test is configured to be skipped when run without "pub serve" ');
        return null;
      }
      break;
  }

  var args = ['--dump-render-tree', '--no-sandbox']
      ..addAll(test.contentShellOptions)
      ..add(url);

  print('run "${contentShellPath} ${args.join(' ')}"');

  return io.Process.start(
      contentShellPath,
      args,
      workingDirectory: workingDir.path).then((p) {
    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      toLines(text).forEach((line) {
        if (PASS_TEST_CASE_REGEX.firstMatch(line) != null) {
          test.results[testType].suiteFailed = false;
          test.results[testType].successCount++;
        } else if (FAIL_TEST_CASE_REGEX.firstMatch(line) != null) {
          test.results[testType].suiteFailed = false;
          test.results[testType].failCount++;
        } else if (FAIL_TEST_SUITE_REGEX.firstMatch(line) != null) {
          test.results[testType].suiteFailed = true;
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
      if (test.results[testType].failCount == 0 &&
          test.results[testType].successCount == 0 &&
          test.results[testType].suiteFailed == false) {
        test.results[testType].suiteFailed = true;
      }
      return ec;
    });
  });
}
