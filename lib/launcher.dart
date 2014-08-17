library bwu_testrunner.launcher;

import 'dart:async' as async;
import 'console_launcher.dart';
import 'package:bwu_testrunner/content_shell_launcher.dart';
import 'package:bwu_testrunner/config.dart';
import 'package:bwu_testrunner/result.dart';

// TODO(zoechi) split Launcher base class and Launcher wrapper into two classes

abstract class LauncherFactory {
  Launcher newInstance(String name, Map config);
}

//class LauncherWrapper extends Launcher {
//  final String name;
//  final Launcher wrappedLauncher;
//
//
//  LauncherConfig _config;
//  LauncherConfig get config => _config;
//
//  @override
//  LauncherWrapper._(this.name, this.wrappedLauncher, Map config) : super.protected() {
//    _config = wrappedLauncher.parseConfig(config);
//  }
//
//  async.Future<LauncherResult> launch(Test test) {
//    return wrappedLauncher.launch(test);
//  }
//  @override
//  LauncherConfig parseConfig(Map config) => wrappedLauncher.parseConfig(config);
//}

abstract class Launcher  {

  static final Map _registeredLauncherFactories = <String,LauncherFactory>{
    'console': new ConsoleLauncherFactory(),
    'content_shell': new ContentShellLauncherFactory()
  };

  static registerLauncher(String launcherId, Launcher launcher) => _registeredLauncherFactories[launcherId] = launcher;

  factory Launcher(String name, String launcherId, Map config) {
    var factory = _registeredLauncherFactories[launcherId];
    if(factory == null) {
      throw 'Launcher "${launcherId}" unknown.';
    }

    return factory.newInstance(name, config);
  }

  final String name;
  Launcher.protected(this.name);

//  LauncherConfig parseConfig(Map config);

  LauncherConfig get config;

  async.Future<LauncherResult> launch(Test test);

  void tearDown();
}

abstract class LauncherConfig {
  Duration timeout;

  LauncherConfig(Map config, {int timeoutSeconds: 120}) {
    if(timeoutSeconds == null) {
      timeoutSeconds = 120;
    }
    var to = config['timeout'];
    if(to != null) {
      if(to is! int) {
        throw 'Timeout value "${to}" must be an integer value and defines the timeout in seconds.';
      } else {
        timeoutSeconds = to;
      }
    }

    timeout = new Duration(seconds: timeoutSeconds);
  }
}