
library bwu_testrunner.group_with_one_skipped_test;

import 'package:unittest/unittest.dart';

void main() {

  group('Group with one skipped test', () {

    skip_test('skipped test', () {
      expect(true, isTrue);
    });
  });
}
