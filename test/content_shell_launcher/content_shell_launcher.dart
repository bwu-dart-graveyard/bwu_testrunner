library bwu_testrunner.test.console_launcher;

import 'dart:io' as io;
import 'dart:async' as async;
import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/content_shell_launcher.dart';
import 'package:bwu_testrunner/content_shell.dart';
import 'package:bwu_testrunner/pub_serve.dart';

void main() {

  unittestConfiguration.timeout = new Duration(minutes: 4);

  dartSdkPath = io.Platform.environment['DART_SDK'];
  workingDir = io.Directory.current.parent.parent;
  pubServePort = 18080;

  group('ContentShellLauncher -', () {

    setUp(() {
    });

    tearDown(() {
      shutdownPubServe();
    });

    var usePubServeText = (ContentShellLauncherResult result) =>
        ' (usePubServe: ${(result.launcher.config as ContentShellLauncherConfig).usePubServe})';

    test('group with one succeeding test', () {
      var configs = TestConfig.load('group_with_one_succeeding_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);


      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('group_with_one_succeeding_test'), reason: 'test.name ${usePubServe}');
            expect(testResult.exitCode, equals(0), reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(0), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(1), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
            // TODO(zoechi) verify testResult.output (on each test)
          });
        });
      }));

    });

    test('group with one failing test', () {
      var configs = TestConfig.load('group_with_one_failing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      return async.Future.wait(config.launchers/*.where((e) => !e.config.usePubServe)*/.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('group_with_one_failing_test'), reason: 'test.name ${usePubServe}');
            // exitCode is always 0 with content_shell even when the test fails
            expect(testResult.exitCode, equals(0), reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(1), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(0), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
          });
        });
      }));
    });

    test('group with one throwing test', () {
      var configs = TestConfig.load('group_with_one_throwing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('group_with_one_throwing_test'), reason: 'test.name ${usePubServe}');
            // exitCode is always 0 with content_shell even when the test fails
            expect(testResult.exitCode, equals(0), reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(1), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(0), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
          });
        });
      }));
    });

    test('group with one succeeding one failing one throwing test', () {
      var configs = TestConfig.load('group_with_one_succeeding_one_failing_one_throwing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('group_with_one_succeeding_one_failing_one_throwing_test'), reason: 'test.name ${usePubServe}');
            // exitCode is always 0 with content_shell even when the test fails
            expect(testResult.exitCode, equals(0), reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(2), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(1), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
          });
        });
      }));
    });

    test('group with one skipped test', () {
      var configs = TestConfig.load('group_with_one_skipped_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('group_with_one_skipped_test'), reason: 'test.name ${usePubServe}');
            // exitCode is always 0 with content_shell even when the test fails
            expect(testResult.exitCode, equals(0), reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(0), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(0), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            expect(testResult.suiteFailed, isTrue, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
          });
        });
      }));
    });

    test('skipped group test', () {
      var configs = TestConfig.load('skipped_group_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            if((testResult.launcher.config as ContentShellLauncherConfig).usePubServe) {
              expect(testResult.launcher.config.timeout, equals(new Duration(seconds: 40)));
            } else {
              expect(testResult.launcher.config.timeout, equals(new Duration(seconds: 20)));
            }
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('skipped_group_test'), reason: 'test.name ${usePubServe}');
            // when content_shell is killed due to timeout the exit code is != 0 (-9 on Linux)
            expect(testResult.exitCode != 0, isTrue, reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(0), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(0), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            // suiteFailed is true on timeout because we can't know whether there is
            // no test or a test hangs.
            // The same test run from the console doesn't time out and therefore the
            // distinction is clear.
            expect(testResult.suiteFailed, isTrue, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
          });
        });
      }));
    });


    test('non-existing test', () {
      var configs = TestConfig.load('non_existing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ContentShellLauncherResult testResult) {
            var usePubServe = usePubServeText(testResult);
            expect(testResult.test, isNotNull, reason: 'test != null ${usePubServe}');
            expect(testResult.test.name, equals('non_existing_test'), reason: 'test.name ${usePubServe}');
            expect(testResult.exitCode, equals(0), reason: 'exitCode ${usePubServe}');
            expect(testResult.failCount, equals(0), reason: 'failCount ${usePubServe}');
            expect(testResult.successCount, equals(0), reason: 'successCount ${usePubServe}');
            expect(testResult.isSkipped, isFalse, reason: 'isSkipped ${usePubServe}');
            expect(testResult.suiteFailed, isTrue, reason: 'suiteFailed ${usePubServe}');
            expect(testResult.launcher, isNotNull, reason: 'launcher != null ${usePubServe}');
          });
        });
      }));
    });

  });
}
