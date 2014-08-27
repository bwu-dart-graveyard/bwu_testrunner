library bwu_testrunner.groupe_with_one_succeeding_test;

import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/server/unittest_configuration.dart' as utc;

void main() {
//  var _config = new utc.UnittestConfiguration(testMain);
//  unittestConfiguration = _config;
//  _config.onFileTestResult.listen((t) {
//    print(t);
//  });
//  _config.onTestProgress.listen((t) {
//    print(t);
//  });
//
////  _config.getTests().then((e) {
////    print(e);
////  });
//  _config.runTests().then((e) {
//    print(e);
//  });
  testMain();
}

void testMain() {

  group('Test - A group with one succeeding test', () {

    test('succeding test', () {
      expect(true, isTrue);
    });
  });
}
