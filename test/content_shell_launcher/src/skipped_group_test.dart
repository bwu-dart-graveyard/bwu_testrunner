library bwu_testrunner.test.content_shell_launcher.skipped_group_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_config.dart" show useHtmlConfiguration;

import 'package:bwu_testrunner/server/browser_testrunner.dart'; // TODO remove

void main() {
  new BrowserTestrunner(mainx);
}

void mainx() {
  //useHtmlConfiguration();

  skip_group("Skipped group test -", () {

    test("some test", () {
      expect(true, isTrue);
    });
  });

  skip_test("some test", () {
    expect(true, isTrue);
  });

}
