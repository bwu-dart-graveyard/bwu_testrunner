library bwu_testrunner.test.load_config;

import 'package:unittest/unittest.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/console_launcher.dart';
import 'package:bwu_testrunner/content_shell_launcher.dart';


void main() {
  group('Load config -', () {

    test('simple test', () {
      var configs = TestConfig.load('run_config.json');
      var config = configs["default"];
      expect(config, isNotNull);
      expect(config.launchers.length, equals(4));
      expect(config.tests.length, equals(1));

      var consoleLauncher = config.launchers
          .firstWhere((l) => l.name == 'console');
      expect(consoleLauncher, isNotNull);
      expect(consoleLauncher.wrappedLauncher, new isInstanceOf<ConsoleLauncher>());

      var csLauncher1 = config.launchers
          .firstWhere((l) => l.name == 'content_shell, pub serve');
      expect(csLauncher1, isNotNull);
      var csLauncherConfig1 = (csLauncher1.config as ContentShellLauncherConfig);
      expect(csLauncherConfig1, isNotNull);
      expect(csLauncherConfig1.usePubServe, isTrue);
      expect(csLauncherConfig1.contentShellOptions.length, equals(0));

      var csLauncher2 = config.launchers
          .firstWhere((l) => l.name == 'content_shell, allow popups');
      expect(csLauncher2, isNotNull);
      var csLauncherConfig2 = (csLauncher2.config as ContentShellLauncherConfig);
      expect(csLauncherConfig2, isNotNull);
      expect(csLauncherConfig2.usePubServe, isFalse);
      expect(csLauncherConfig2.contentShellOptions ,
          unorderedEquals(["--disable-popup-blocking"]));

      var csLauncher3 = config.launchers
          .firstWhere((l) => l.name == 'content_shell, file access');
      expect(csLauncher3, isNotNull);
      var csLauncherConfig3 = (csLauncher3.config as ContentShellLauncherConfig);
      expect(csLauncherConfig3, isNotNull);
      expect(csLauncherConfig3.usePubServe, isFalse);
      expect(csLauncherConfig3.contentShellOptions ,
          unorderedEquals(["--allow-external-pages", "--allow-file-access-from-files"]));
    });

    test('config with unknown launcher should throw', () {
      var load = () => TestConfig.load('unknown_launcher_config.json');
      expect(load, throwsA(new isInstanceOf<String>()));
    });

  });
}
