library bwu_testrunner.config;

import 'dart:io' as io;
import 'dart:convert' show JSON;
import 'package:bwu_testrunner/util.dart';
//import 'package:bwu_testrunner/result.dart';
import 'package:bwu_testrunner/launcher.dart';

const CONTENT_SHELL_OPTIONS = 'contentShellOptions';

class TestConfig {
//  Map<List<String>, TestResult> results = <List<String>, TestResult>{
      //TestType.FILE: new TestResult(TestType.FILE),
      //TestType.PUB_SERVE: new TestResult(TestType.PUB_SERVE)
//  };


  final List<Launcher> launchers = <Launcher>[];
  final List<Test> tests = <Test>[];

  TestConfig();

  TestConfig.fromConfig(Map configData) {
    var t = configData['tests'] as Map;
    if(t == null || t.length == 0) {
      // throw "No launcher configured.";
    } else {
      (t).forEach((k, v) {
        tests.add(new Test(k, v));
      });
    }

    var l = configData['launchers'] as Map;
    if(l == null || l.length == 0) {
      throw "No launcher configured.";
    } else {
      (l).forEach((k, v) {
        if(v['type'] == null) {
          throw 'No launcher type configured for launcher "${k}".';
        }
        launchers.add(new Launcher(k, v["type"], v));
      });
    }
  }

  static Map<String,TestConfig> load(String path) {
    var tests = <String,TestConfig>{};

    writeln('Using config file "${path}".');
    var config = new io.File(path).readAsStringSync();
    var configData = JSON.decode(config);

    var testConfigs = <String,TestConfig>{};
    configData.keys.forEach((configName) {
      testConfigs[configName] = new TestConfig.fromConfig(configData[configName]);
    });

    return testConfigs;
  }
}

class Test {
  final String name;
  String path = '';
  bool skip = false;
  final skipLaunchers = <String>[];

  Test(this.name, Map configData) {
    if(configData['path'] != null) {
      path = configData["path"];
    }

    if(configData['skip'] != null) {
      skip = configData["skip"];
    }
  }
}
