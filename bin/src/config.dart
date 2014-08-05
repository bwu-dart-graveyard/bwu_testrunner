part of bwu_testrunner.run;

const CONTENT_SHELL_OPTIONS = 'contentShellOptions';
const SKIP_CONTENTSHELL_TEST = 'skipContentShellTest';
const SKIP_PUBSERVE_TEST = 'skipPubServeTest';
const SKIP_FILE_TEST = 'skipFileTest';

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
    if (configData.containsKey(CONTENT_SHELL_OPTIONS) &&
    configData[CONTENT_SHELL_OPTIONS] != null) {
      contentShellOptions = configData[CONTENT_SHELL_OPTIONS];
    }
    if (configData.containsKey(SKIP_CONTENTSHELL_TEST) &&
    configData[SKIP_CONTENTSHELL_TEST] != null) {
      skipContentShellTest = configData[SKIP_CONTENTSHELL_TEST];
    }
    if (configData.containsKey(SKIP_PUBSERVE_TEST) &&
    configData[SKIP_PUBSERVE_TEST] != null) {
      skipPubServeTest = configData[SKIP_PUBSERVE_TEST];
    }
    if (configData.containsKey(SKIP_FILE_TEST) &&
    configData[SKIP_FILE_TEST] != null) {
      skipFileTest = configData[SKIP_FILE_TEST];
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

