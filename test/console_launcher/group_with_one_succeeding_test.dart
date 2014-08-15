
library bwu_testrunner.group_with_one_succeeding_test;

import 'package:unittest/unittest.dart';

void main() {

  group('Group with one succeeding test -', () {

    test('succeding test', () {
      expect(true, isTrue);
    });
  });
}
