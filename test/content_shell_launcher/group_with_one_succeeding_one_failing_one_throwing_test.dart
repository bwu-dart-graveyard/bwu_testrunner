library bwu_testrunner.test.content_shell_launcher.group_with_one_succeeding_one_failing_one_throwing_test;

import 'package:unittest/unittest.dart';
import "package:unittest/html_config.dart" show useHtmlConfiguration;

void main() {
  useHtmlConfiguration();

  group('Group with one succeeding one failing one throwing test -', () {

    test('succeding test', () {
      expect(true, isTrue);
    });

    test('failing test', () {
      expect(true, isFalse);
    });

    test('failing test', () {
      throw 'anything';
    });

  });
}
