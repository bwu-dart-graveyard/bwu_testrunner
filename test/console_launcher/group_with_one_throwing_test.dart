
library bwu_testrunner.group_with_one_throwing_test;

import 'package:unittest/unittest.dart';

void main() {

  group('A group with one throwing test -', () {

    test('throwing test', () {
      throw 'anything';
    });
  });
}
