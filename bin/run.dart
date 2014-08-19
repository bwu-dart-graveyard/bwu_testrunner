#!/bin/dart
library bwu_testrunner.run;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:convert' show UTF8;
//import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:path/path.dart' as path;

import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/result.dart';
import 'package:bwu_testrunner/util.dart';

import 'package:bwu_testrunner/content_shell.dart';
import 'package:bwu_testrunner/pub_serve.dart';

part 'package:bwu_testrunner/args.dart';

// A list of possible options for Chromium can be found at http://peter.sh/experiments/chromium-command-line-switches/

Map<String,TestConfig> tests;
bool runPubServeTests = true;
bool runFileTests = true;
int pubServePort;
String dartSdkPath;
bool isInstallContentShell = false;
io.Directory workingDir;
String configFilePath;

void main(List<String> args) {
  workingDir = io.Directory.current;
  writeln('current working directory: ${workingDir}');
//  contentShellPath = 'content_shell';
  contentShellDownloadPath = workingDir.absolute.path;

  processArgs(args);

  tests = TestConfig.load(path.join(workingDir.path, configFilePath));

  var future = new async.Future.value();

  if (isInstallContentShell) {
    io.Directory.current = contentShellDownloadPath;
    writeln('Download content_shell archive to "${contentShellDownloadPath}');

    future = future.then((e) => installContentShell()).then((e) {
      io.Directory.current = workingDir;
    });
  }

  io.Process pubServe;
  if (runPubServeTests) {
    future = future.then((e) => runPubServe()).then((p) {
      pubServe = p;
      p.exitCode.then((ec) {
        writeln('pub serve ended with exit code $ec');
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

final PASS_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(PASS).+?.*$');
final FAIL_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(FAIL|ERROR).+?.*$');
final FAIL_TEST_SUITE_REGEX = new RegExp(r'^FAIL$');

async.Future runTest(String testName, TestType testType) {
  var test = tests[testName]
      ..results[testType].name = testName;

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
    writeln(
        'Skipping test "${testName}". Test is configured to be skipped when run in "content_shell" ');
    return null;
  }

  switch (testType) {
    case TestType.PUB_SERVE:
      if (test.skipPubServeTest) {
        test.results[testType].isSkipped = true;
        writeln(
            'Skipping test "${testName}". Test is configured to be skipped when run with "pub serve" ');
        return null;
      }
      break;

    case TestType.FILE:
      if (test.skipFileTest) {
        test.results[testType].isSkipped = true;
        writeln(
            'Skipping test "${testName}". Test is configured to be skipped when run without "pub serve" ');
        return null;
      }
      break;
  }

  var args = ['--dump-render-tree', '--no-sandbox']
      ..addAll(test.contentShellOptions)
      ..add(url);

  writeln('run "${contentShellPath} ${args.join(' ')}"');

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
        writeln('CS | $line');
      });
    });
    p.stderr.listen((stdErr) {
      var text = UTF8.decoder.convert(stdErr);
      toLines(text).forEach((line) {
        writelnErr('CS err | $line');
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
