library bwu_testrunner.group_with_one_failing_test;
//xxxx
import 'package:unittest/unittest.dart';

void main() {

  group('Group with one failing test', () {

    test('failing test', () {
      expect(true, isFalse);
    });
  });
}
