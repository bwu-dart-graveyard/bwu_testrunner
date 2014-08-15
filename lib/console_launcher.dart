library bwu_testrunner.console_launcher;

import 'launcher.dart';


class ConsoleLauncher extends Launcher {
  ConsoleLauncher() : super.protected();

  @override
  ConsoleLauncherConfig parseConfig(Map config) {
    return new ConsoleLauncherConfig(config);
  }
}

class ConsoleLauncherConfig extends LauncherConfig {
  ConsoleLauncherConfig(Map config) : super(config);
}