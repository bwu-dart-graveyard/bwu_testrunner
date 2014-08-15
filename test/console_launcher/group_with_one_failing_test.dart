
library bwu_testrunner.groupe_with_one_failing_test;

import 'package:unittest/unittest.dart';

void main() {

  group('Group with one failing test -', () {

    test('failing test', () {
      expect(true, isFalse);
    });
  });
}
