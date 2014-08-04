part of bwu_testrunner.run;

class TestConfig {
  Map<TestType, TestResult> results = <TestType, TestResult>{
      TestType.FILE: new TestResult(TestType.FILE),
      TestType.PUB_SERVE: new TestResult(TestType.PUB_SERVE)
  };
  bool skipContentShellTest = false;
  bool skipPubServeTest = false;
  bool skipFileTest = false;
  List<String> contentShellOptions = [];
  String path = '';

  TestConfig({this.contentShellOptions, this.skipContentShellTest,
             this.skipPubServeTest, this.skipFileTest, this.path}) {
    assert(contentShellOptions != null);
    assert(skipContentShellTest != null);
    assert(skipPubServeTest != null);
    assert(skipFileTest != null);
    assert(path != null);
  }

  TestConfig.fromConfig(Map configData) {
    if (configData.containsKey('contentShellOptions') &&
    configData['contentShellOptions'] != null) {
      contentShellOptions = configData['contentShellOptions'];
    }
    if (configData.containsKey('skipContentShellTest') &&
    configData['skipContentShellTest'] != null) {
      skipContentShellTest = configData['skipContentShellTest'];
    }
    if (configData.containsKey('skipPubServeTest') &&
    configData['skipPubServeTest'] != null) {
      skipPubServeTest = configData['skipPubServeTest'];
    }
    if (configData.containsKey('skipFileTest') &&
    configData['skipFileTest'] != null) {
      skipPubServeTest = configData['skipFileTest'];
    }
    if (configData.containsKey('path') && configData['path'] != null) {
      path = configData['path'];
    }
  }
}

class TestType {
  static const PUB_SERVE = const TestType._(1);
  static const FILE = const TestType._(2);

  static get values => const [PUB_SERVE, FILE];

  final int value;

  const TestType._(this.value);
}

void loadConfigFile() {
  var configFile = path.join(workingDir.path, configFilePath);
  print('Using config file "${configFile}".');
  var config = new io.File(configFile).readAsStringSync();
  var configData = JSON.decode(config);
  configData.keys.forEach((testName) {
    tests[testName] = new TestConfig.fromConfig(configData[testName]);
  });
}

