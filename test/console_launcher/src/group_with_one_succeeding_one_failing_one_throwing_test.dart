
library bwu_testrunner.group_with_one_succeeding_one_failing_one_throwing_test;

import 'package:unittest/unittest.dart';

void main() {

  group('Group with one succeeding one failing one throwing test', () {

    test('succeding test', () {
      expect(true, isTrue);
    });

    test('failing test', () {
      expect(true, isFalse);
    });

    test('throwing test', () {
      throw 'anything';
    });

  });
}
