library bwu_testrunner.test.console_launcher;

import 'dart:async' as async;

import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/console_launcher.dart';
import 'package:bwu_testrunner/result.dart';
import 'package:bwu_testrunner/result_report_print.dart';

void main() {

  group('ConsoleLauncher -', () {

    test('result report print test', () {
      var configs = TestConfig.load('src/result_report_print_test_run_config.json');
      var config = configs['default'];
      expect(config, isNotNull);

      var results = <LauncherResult>[];
      return async.Future.wait(config.launchers.expand((launcher) {
        return config.tests.map((test) {
          return launcher.launch(test).then((ConsoleLauncherResult testResult) {
            results.add(testResult);
          });
        });

      }))
      .then((e) {
        new ResultReportPrint(results);
      });

    });

  });
}
