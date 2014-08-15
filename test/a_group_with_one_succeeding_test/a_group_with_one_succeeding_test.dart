
library bwu_testrunner.groupe_with_one_succeeding_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_config.dart" show useHtmlConfiguration;

void main() {
  useHtmlConfiguration();

  group("A group with one succeeding test", () {

    test("succeding test", () {
      expect(true, isTrue);
    });
  });
}
