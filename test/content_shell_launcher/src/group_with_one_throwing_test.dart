library bwu_testrunner.test.content_shell_launcher.group_with_one_throwing_test;

import 'package:unittest/unittest.dart';
import "package:unittest/html_config.dart" show useHtmlConfiguration;

void main() {
  useHtmlConfiguration();

  group('A group with one throwing test', () {

    test('throwing test', () {
      throw 'anything';
    });
  });
}
