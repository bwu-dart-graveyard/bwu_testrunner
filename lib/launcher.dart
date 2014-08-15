library bwu_testrunner.launcher;

import 'dart:async' as async;
import 'console_launcher.dart';
import 'package:bwu_testrunner/content_shell_launcher.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/result.dart';

// TODO(zoechi) split Launcher base class and Launcher wrapper into two classes
class Launcher {

  static final Map _registeredLaunchers = <String,Launcher>{
    'console': new ConsoleLauncher(),
    'content_shell': new ContentShellLauncher()
  };

  registerLauncher(String launcherId, Launcher launcher) => _registeredLaunchers[launcherId] = launcher;

  factory Launcher(String name, String launcherId, Map config) {
    var innerLauncher = _registeredLaunchers[launcherId];
    if(innerLauncher == null) {
      throw 'Launcher "${launcherId}" unknown.';
    }

    return new Launcher._(name, innerLauncher, config);
  }

  /***
   * Use in derived classes.
   */
  Launcher.protected() : wrappedLauncher = null;

  /**
   * wrapped launcher
   */
  final Launcher wrappedLauncher;

  String name;
  LauncherConfig _config;
  LauncherConfig get config => _config;

  Launcher._(this.name, this.wrappedLauncher, Map config) {
    _config = wrappedLauncher.parseConfig(config);
  }

  LauncherConfig parseConfig(Map config) => null;

  async.Future<LauncherResult> launch(Test test, LauncherConfig config) {
    return wrappedLauncher.launch(test, config);
  }
}

abstract class LauncherConfig {
  LauncherConfig(Map config);
}