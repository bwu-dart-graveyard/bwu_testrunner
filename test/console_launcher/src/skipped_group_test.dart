
library bwu_testrunner.skipped_group_test;

import "package:unittest/unittest.dart";

void main() {

  skip_group("Skipped group test -", () {

    test("some test", () {
      expect(true, isTrue);
    });
  });
}
