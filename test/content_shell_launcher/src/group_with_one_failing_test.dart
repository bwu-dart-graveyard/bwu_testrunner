library bwu_testrunner.test.content_shell_launcher.groupe_with_one_failing_test;

import 'package:unittest/unittest.dart';
import "package:unittest/html_config.dart" show useHtmlConfiguration;

void main() {
  useHtmlConfiguration();

  group('Group with one failing test', () {

    test('failing test', () {
      expect(true, isFalse);
    });
  });
}
