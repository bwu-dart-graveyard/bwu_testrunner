library bwu_testrunner.groupe_with_one_succeeding_test;

import 'package:unittest/unittest.dart';
//xxxxxxxx
void main() {
  group('Test - A group with one succeeding test', () {

    test('succeding test', () {
      expect(true, isTrue);
    });
  });
}
