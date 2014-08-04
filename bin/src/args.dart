part of bwu_testrunner.run;

void processArgs(List<String> args) {
  const PORT_OPTION = 'port';
  const CONFIG_FILE_OPTION = 'config-file';
  const TEST_NAME_OPTION = 'test-name';
  const DART_SDK_PATH_OPTION = 'dart-sdk-path';
//  const WORKING_DIR_OPTION = 'package-root';
  const CONTENT_SHELL_PATH_OPTION = 'contentshell-path';
  const CONTENT_SHELL_DOWNLOAD_PATH_OPTION = 'contentshell-download-path';

  const NO_PUB_SERVE_FLAG = 'no-pub-serve';
  const NO_FILE_FLAG = 'no-file';
  const HELP_FLAG = 'help';
  const INSTALL_CONTENTSHELL_FLAG = 'install-contentshell';

  var parser = new ArgParser();

  parser.addOption(
      PORT_OPTION,
      defaultsTo: '18080',
      abbr: 'p',
      help: 'The port "pub serve" should serve the content on.');

  parser.addOption(
      CONFIG_FILE_OPTION,
      defaultsTo: 'test/run_config.json',
      abbr: 'c',
      help:
      'The JSON file containing a list of tests to run and optional configuration details for each test.');

  parser.addOption(
      TEST_NAME_OPTION,
      abbr: 't',
      allowMultiple: true,
      help:
      'When a test name is provided only this test is run. This option can be added more than once');

  parser.addOption(
      DART_SDK_PATH_OPTION,
      abbr: 'd',
      help: 'The path to the DART SDK directory.');

//  parser.addOption(WORKING_DIR_OPTION, abbr: 'w',
//      help: 'A path to the directory of your package to tests that contains the "pubspec.yaml" file. Default is the current directory.');

  parser.addOption(
      CONTENT_SHELL_PATH_OPTION,
      abbr: 'o',
      help: 'The path of the "content_shell" executable.');

  parser.addOption(
      CONTENT_SHELL_DOWNLOAD_PATH_OPTION,
      abbr: 'n',
      help:
      'The path of the "content_shell" download archive should be downloaded and extracted to.');

  parser.addFlag(
      NO_PUB_SERVE_FLAG,
      defaultsTo: true,
      negatable: false,
      abbr: 's',
      help: 'Don\'t run tests with "pub serve".');

  parser.addFlag(
      NO_FILE_FLAG,
      defaultsTo: true,
      negatable: false,
      abbr: 'f',
      help: 'Don\'t run tests from files.');

  parser.addFlag(
      HELP_FLAG,
      abbr: 'h',
      help: 'Print usage information.',
      negatable: false);

  parser.addFlag(
      INSTALL_CONTENTSHELL_FLAG,
      abbr: 'i',
      defaultsTo: false,
      negatable: false,
      help:
      'Execute "download_contentshell.sh" script if content_shell can not be found.');

  try {
    var ar = parser.parse(args);

    if (ar[HELP_FLAG]) {
      print(parser.getUsage());
      io.Directory.current = workingDir;
      io.exit(0);
    }

    pubServePort = int.parse(ar[PORT_OPTION]);
    runPubServeTests = ar[NO_PUB_SERVE_FLAG];
    runFileTests = ar[NO_FILE_FLAG];

    if (ar.rest.length != 0) {
      print(parser.getUsage());
      fail(1);
    }

    configFilePath = ar[CONFIG_FILE_OPTION];

    if (ar[TEST_NAME_OPTION] != null) {
      List<String> testNames = ar[TEST_NAME_OPTION];
      if (testNames.length > 0) {
        tests.keys.forEach((testName) {
          if (testNames.contains(testName)) {
            tests[testName].skipContentShellTest = false;
            tests[testName].skipPubServeTest = false;
            tests[testName].skipFileTest = false;
          } else {
            tests[testName].skipContentShellTest = true;
          }
        });
      }
    }

    if (ar[INSTALL_CONTENTSHELL_FLAG]) {
      isInstallContentShell = true;
      if (ar[DART_SDK_PATH_OPTION] != null) {
        dartSdkPath = ar[DART_SDK_PATH_OPTION];
      } else {
        if (io.Platform.environment.containsKey('DART_SDK')) {
          dartSdkPath = io.Platform.environment['DART_SDK'];
        }
      }
    }

//    if(ar[WORKING_DIR_OPTION] != null) {
//      workingDir = new io.Directory(ar[WORKING_DIR_OPTION]);
//      io.Directory.current = workingDir;
//      print('Changed current working directory to : ${workingDir}');
//    }

    if (ar[CONTENT_SHELL_PATH_OPTION] != null) {
      contentShellPath = path.join(
          workingDir.absolute.path,
          ar[CONTENT_SHELL_PATH_OPTION]);
    }

    if (ar[CONTENT_SHELL_DOWNLOAD_PATH_OPTION] != null) {
      contentShellDownloadPath = path.join(
          workingDir.absolute.path,
          ar[CONTENT_SHELL_DOWNLOAD_PATH_OPTION]);
    }

  } catch (e, s) {
    print('Parsing args threw: ${e}\n\n${s}');
    print(parser.getUsage());
    fail(1);
  }
}
