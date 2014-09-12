import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/shared/message.dart';

void main() {
  group('ConsoleTestFile', () {

    test('create', () {
      var ctf = new ConsoleTestFile()
        ..responseId = '123'
        ..path = 'some/path';
      expect(1, equals(1));
    });

  });
}
