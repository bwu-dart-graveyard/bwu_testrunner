library bwu_testrunner.console_launcher;

import 'dart:async' as async;
import 'dart:convert' show UTF8;
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'config.dart';
import 'launcher.dart';
import 'result.dart';
import 'util.dart';

class ConsoleLauncherFactory extends LauncherFactory {

  @override
  Launcher newInstance(String name, Map config) {
    return new ConsoleLauncher(name, config, this);
  }
}

class ConsoleLauncher extends Launcher {

  ConsoleLauncherFactory factory;
  ConsoleLauncherConfig _config;
  ConsoleLauncherConfig get config => _config;

  ConsoleLauncher(String name, Map config, ConsoleLauncherFactory factory) : super.protected(name) {
    _config = new ConsoleLauncherConfig(config);
  }

  @override
  async.Future<LauncherResult> launch(Test test) {
    var completer = new async.Completer<LauncherResult>();
    io.Process.start('dart', ['-c', path.join(test.path, '${test.name}.dart')])
    .then((io.Process p) {
      var output = <Output>[];
      var errOutput = new StringBuffer();
      p.stdout.listen((stdOut) {
        var text = UTF8.decoder.convert(stdOut);
        output.add(new Output(text));
        write(text);
      });
      p.stderr.listen((stdErr) {
        var text = UTF8.decoder.convert(stdErr);
        output.add(new Output(text, error: true));
        writeErr(text);
      });
      p.exitCode.then((exitCode) => completer.complete(new ConsoleLauncherResult.parse(this, test, exitCode, output)));
    })
    .catchError((e, s) {
      completer.complete(new ConsoleLauncherResult.parse(this, test, 0, []..add(new Output(s.toString()))));
    });
    return completer.future;
  }

  @override
  void tearDown() {
    // nothing to do
  }
}

class ConsoleLauncherConfig extends LauncherConfig {
  ConsoleLauncherConfig(Map config) : super(config);
}

class ConsoleLauncherResult extends LauncherResult {

  static final PASS_TEST_CASE_REGEX = new RegExp(r'^(PASS):.+?.*$');
  static final FAIL_TEST_CASE_REGEX = new RegExp(r'^(FAIL|ERROR):.+?.*$');
  static final FAIL_TEST_SUITE_REGEX = new RegExp(r'^No tests found.$');

  ConsoleLauncherResult.parse(Launcher launcher, Test test, int exitCode, List<Output> output) : super.parse(launcher, test, exitCode, output) {
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
    });
  }
}