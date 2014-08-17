library bwu_testrunner.testresult;
import 'package:bwu_testrunner/launcher.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/util.dart';

abstract class LauncherResult {
  bool suiteFailed = false;
  int successCount = 0;
  int failCount = 0;
  bool isSkipped = false;

  Launcher launcher;
  Test test;
  int exitCode = 0;
  List<Output> output;
  bool isTimedOut = false;

  //LauncherResult(this.testType);

//  @override
//  String toString() {
//    if (suiteFailed) {
//      return '! FAIL $test.name Test Suite FAIL';
//    } else if (isSkipped) {
//      return '- SKIP $test.name Test Suite SKIP';
//    } else {
//      if (failCount != 0) {
//        return
//          '! FAIL $test.name $failCount FAIL, $successCount PASS (of ${successCount + failCount})';
//      } else {
//        return '  PASS $test.name (all of $successCount)';
//      }
//    }
//  }

  LauncherResult.parse(this.launcher, this.test, this.exitCode, this.output, {this.isTimedOut: false}) {
    assert(launcher != null);
    assert(test != null);
    assert(exitCode != null);
    assert(output != null);
    assert(isTimedOut != null);
  }

  @override
  String toString() => output.map((e) => e.output).join('\n');
}

class Output {
  bool error = false;
  String output;
  Output(this.output, {bool error : false}) {
    if(error == null) error = false;
  }
}

int printResults() {
  writeln('\n');

  bool isFail = false;

  TestType.values.forEach((testType) {
    int failSuitCount = 0;
    int successCount = 0;
    int failCount = 0;
    int skippedSuitesCount = 0;

    switch (testType) {
      case TestType.FILE:
        if (runFileTests) {
          writeln('\n------------------- File tests --------------------');
          tests.keys.forEach(
                  (String test) => print(tests[test].results[TestType.FILE]));
        } else {
          writeln('\n--------------- File tests skipped ----------------');
        }
        break;

      case TestType.PUB_SERVE:
        if (runPubServeTests) {
          writeln('\n----------------- Pub serve tests -----------------');
          tests.keys.forEach(
                  (String test) => writeln(tests[test].results[TestType.FILE]));
        } else {
          writeln('\n------------- Pub serve tests skipped -------------');
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

    writeln('\n===================== SUMMARY =====================');
    if (failSuitCount != 0 || failCount != 0) {
      writelnErr(
          'FAIL - Test Suite: FAIL $failSuitCount PASS ${tests.length - failSuitCount - skippedSuitesCount} (of ${tests.length}) SKIP ${skippedSuitesCount}, Test Case: FAIL $failCount PASS $successCount (of ${failCount + successCount})');
      isFail = true;
    } else {
      writeln(
          'PASS - Suite: ${tests.length - skippedSuitesCount}, Test cases: $successCount, Suites skipped: ${skippedSuitesCount}');
    }
  });

  if (isFail) {
    return 1;
  } else {
    return 0;
  }
}
