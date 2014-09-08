library bwu_testrunner.test.console_launcher;

import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/console_launcher.dart';

void main() {

  group('ConsoleLauncher', () {

    test('group with one succeeding test', () {
      var configs = TestConfig.load('src/group_with_one_succeeding_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('group_with_one_succeeding_test'), reason: 'test.name');
        expect(testResult.exitCode, equals(0), reason: 'exitCode');
        expect(testResult.failCount, equals(0), reason: 'failCount');
        expect(testResult.successCount, equals(1), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

    test('group with one failing test', () {
      var configs = TestConfig.load('src/group_with_one_failing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('group_with_one_failing_test'), reason: 'test.name');
        expect(testResult.exitCode != 0, isTrue, reason: 'exitCode');
        expect(testResult.failCount, equals(1), reason: 'failCount');
        expect(testResult.successCount, equals(0), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

    test('group with one throwing test', () {
      var configs = TestConfig.load('src/group_with_one_throwing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('group_with_one_throwing_test'), reason: 'test.name');
        expect(testResult.exitCode != 0, isTrue, reason: 'exitCode');
        expect(testResult.failCount, equals(1), reason: 'failCount');
        expect(testResult.successCount, equals(0), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

    test('group with one succeeding one failing one throwing test', () {
      var configs = TestConfig.load('src/group_with_one_succeeding_one_failing_one_throwing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('group_with_one_succeeding_one_failing_one_throwing_test'), reason: 'test.name');
        expect(testResult.exitCode != 0, isTrue, reason: 'exitCode');
        expect(testResult.failCount, equals(2), reason: 'failCount');
        expect(testResult.successCount, equals(1), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isFalse, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

    test('group with one skipped test', () {
      var configs = TestConfig.load('src/group_with_one_skipped_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('group_with_one_skipped_test'), reason: 'test.name');
        expect(testResult.exitCode != 0, isTrue, reason: 'exitCode');
        expect(testResult.failCount, equals(0), reason: 'failCount');
        expect(testResult.successCount, equals(0), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isTrue, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

    test('skipped group test', () {
      var configs = TestConfig.load('src/skipped_group_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('skipped_group_test'), reason: 'test.name');
        expect(testResult.exitCode, equals(0), reason: 'exitCode');
        expect(testResult.failCount, equals(0), reason: 'failCount');
        expect(testResult.successCount, equals(0), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isTrue, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

    test('non-existing test', () {
      var configs = TestConfig.load('src/non_existing_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      config.launchers[0].launch(config.tests[0])
      .then(expectAsync((ConsoleLauncherResult testResult) {
        expect(testResult.test, isNotNull, reason: 'test != null');
        expect(testResult.test.name, equals('non_existing_test'), reason: 'test.name');
        expect(testResult.exitCode != 0, isTrue, reason: 'exitCode');
        expect(testResult.failCount, equals(0), reason: 'failCount');
        expect(testResult.successCount, equals(0), reason: 'successCount');
        expect(testResult.isSkipped, isFalse, reason: 'isSkipped');
        expect(testResult.suiteFailed, isTrue, reason: 'suiteFailed');
        expect(testResult.launcher, isNotNull, reason: 'launcher != null');
      }));
    });

  });
}
