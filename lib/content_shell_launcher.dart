library bwu_testrunner.content_shell_launcher;

import 'dart:async' as async;
import 'package:path/path.dart' as path;
import 'config.dart';
import 'content_shell.dart';
import 'launcher.dart';
import 'pub_serve.dart';
import 'result.dart';
import 'util.dart';


class ContentShellLauncher extends Launcher {
  ContentShellLauncher() : super.protected();

  @override
  ContentShellLauncherConfig parseConfig(Map config) {
    return new ContentShellLauncherConfig(config);
  }

  @override
  async.Future<LauncherResult> launch(Test test, ContentShellLauncherConfig config) {
    var completer = new async.Completer<LauncherResult>();
    installContentShell()
    .then((_) {
      var url;
      if(config.usePubServe) {
        url =
            'http://localhost:${pubServePort}/${path.join(test.path, '${test.name}.html')}';
      } else {
        url = path.join('test', test.path, '${test.name}.html');
      }

      var future;
      if(config.usePubServe) {
        future = runPubServe();
      } else {
        future = new async.Future.value(true);
      }
      future = future.then((_) {
        var args = ['--dump-render-tree', '--no-sandbox']
             ..addAll(config.contentShellOptions)
             ..add(url);
        writeln('run "${contentShellPath} ${args.join(' ')}"');
      });
    });
    return completer.future;
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