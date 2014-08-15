library bwu_testrunner.content_shell_launcher;

import 'launcher.dart';


class ContentShellLauncher extends Launcher {
  ContentShellLauncher() : super.protected();

  @override
  ContentShellLauncherConfig parseConfig(Map config) {
    return new ContentShellLauncherConfig(config);
  }
}

class ContentShellLauncherConfig extends LauncherConfig {

  bool usePubServe = false;
  final List<String> contentShellOptions = [];

  ContentShellLauncherConfig(Map config) : super(config) {
    var ps = config['pub-serve'];
    if(ps != null) {
      usePubServe = ps;
    }

    var csOptions = config["contentShellOptions"];
    if(csOptions != null) {
      contentShellOptions.addAll(csOptions);
    }
  }
}