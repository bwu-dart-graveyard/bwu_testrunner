library bwu_testrunner.test.content_shell_launcher.group_with_one_succeeding_test;

import 'package:unittest/unittest.dart';
import "package:unittest/html_config.dart" show useHtmlConfiguration;

void main() {
  useHtmlConfiguration();

  group('Group with one succeeding test', () {

    test('succeding test', () {
      expect(true, isTrue);
    });
  });
}
