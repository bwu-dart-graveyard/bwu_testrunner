library bwu_testrunner.test.content_shell_launcher.skipped_group_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_config.dart" show useHtmlConfiguration;

void main() {
  useHtmlConfiguration();

  skip_group("Skipped group test -", () {

    test("some test", () {
      expect(true, isTrue);
    });
  });

  skip_test("some test", () {
    expect(true, isTrue);
  });

}
