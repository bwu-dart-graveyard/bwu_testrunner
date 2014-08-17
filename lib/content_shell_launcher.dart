library bwu_testrunner.content_shell_launcher;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:convert' show UTF8;
import 'package:path/path.dart' as path;
import 'config.dart';
import 'content_shell.dart';
import 'launcher.dart';
import 'pub_serve.dart';
import 'result.dart';
import 'util.dart';
import 'package:bwu_testrunner/timeout_manager.dart';

class ContentShellLauncherFactory extends LauncherFactory {

  @override
  ContentShellLauncher newInstance(String name, Map config) {
    return new ContentShellLauncher(name, config, this);
  }
}

class ContentShellLauncher extends Launcher {

  ContentShellLauncherFactory factory;
  ContentShellLauncherConfig _config;
  ContentShellLauncherConfig get config => _config;

  ContentShellLauncher(String name, Map config, ContentShellLauncherFactory factory) : super.protected(name) {
    _config = new ContentShellLauncherConfig(config);
  }

  @override
  async.Future<LauncherResult> launch(Test test) {
    assert(workingDir != null);

    var completer = new async.Completer<LauncherResult>();
    installContentShell()
    .then((_) {
      var url;
      var future;
      if(_config.usePubServe) {
        url =
            'http://localhost:${pubServePort}/${path.join(test.path, '${test.name}.html')}';
        future = runPubServe();
      } else {
        url = path.join('test', test.path, '${test.name}.html');
        future = new async.Future.value(true);
      }
      future.then((_) {
        var args = ['--dump-render-tree', '--no-sandbox']
             ..addAll(_config.contentShellOptions)
             ..add(url);

        writeln('run "${contentShellPath} ${args.join(' ')}"');

        io.Process.start(contentShellPath,
            args,
            workingDirectory: workingDir.path)
        .then((io.Process p) {

          var output = <Output>[];

          bool isTimedOut = false;
          var timeoutManager = new TimeoutManager(_config.timeout, () {
            isTimedOut = true;
            p.kill(io.ProcessSignal.SIGKILL);
          });

          var errOutput = new StringBuffer();
          p.stdout.listen((stdOut) {
            timeoutManager.update();
            var text = UTF8.decoder.convert(stdOut);
            output.add(new Output(text));
            write(text);
          });
          p.stderr.listen((stdErr) {
            timeoutManager.update();
            var text = UTF8.decoder.convert(stdErr);
            output.add(new Output(text, error: true));
            writeErr(text);
          });
          p.exitCode.then((exitCode) {
            timeoutManager.cancel();
            completer.complete(new ContentShellLauncherResult.parse(this, test, exitCode, output, isTimedOut: isTimedOut));
          });
        });
      });
    });
    return completer.future;
  }

  @override
  void tearDown() {
    shutdownPubServe();
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

class ContentShellLauncherResult extends LauncherResult {

  static final PASS_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(PASS).+?.*$');
  static final FAIL_TEST_CASE_REGEX = new RegExp(r'^\d+?.+?(FAIL|ERROR).+?.*$');
  static final FAIL_TEST_SUITE_REGEX = new RegExp(r'^FAIL$');

  ContentShellLauncherResult.parse(Launcher launcher, Test test, int exitCode, List<Output> output, {bool isTimedOut : false}) : super.parse(launcher, test, exitCode, output, isTimedOut: isTimedOut) {
    suiteFailed = true;
    output.forEach((o) {
      toLines(o.output).forEach((line) {
        if (PASS_TEST_CASE_REGEX.firstMatch(line) != null) {
          suiteFailed = false;
          successCount++;
        } else if (FAIL_TEST_CASE_REGEX.firstMatch(line) != null) {
          suiteFailed = false;
          failCount++;
        } else if (FAIL_TEST_SUITE_REGEX.firstMatch(line) != null) {
          suiteFailed = true;
        }
      });
      if(isTimedOut) {
        suiteFailed = true;
      }
    });
  }
}