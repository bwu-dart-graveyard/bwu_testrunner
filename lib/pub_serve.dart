library bwu_testrunner.pub_serve;

import 'dart:async' as async;
import 'dart:io' as io;
import 'dart:convert' show UTF8;
import 'util.dart';

io.Process _pubServeProcess;
io.Process get pubServeProcess => _pubServeProcess;
bool _isPubServeStarting = false;
async.Completer _completer;

int pubServePort;
io.Directory workingDir;

async.Future<io.Process> runPubServe() {
  writeln('launching pub serve --port $pubServePort test');
  if(pubServeProcess != null) {
    return new async.Future.value(_pubServeProcess);
  }

  if(_isPubServeStarting) {
    return _completer.future;
  }

  _completer = new async.Completer();
  _isPubServeStarting = true;

  return io.Process.start(
      'pub',
      ['serve', '--port', pubServePort.toString(), 'test'],
      workingDirectory: workingDir.path).then((p) {

    _pubServeProcess = p;

    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      toLines(text).forEach((line) {
        writeln('PUB | $line');
      });


      // 'Build completed' may occur more then once but complete must not be called more than once
      if (!_completer.isCompleted &&
      text.contains(new RegExp('Build completed.*'))) {
        _completer.complete(p);
      }
    });
    p.stderr.listen((stdErr) {
      var text = UTF8.decoder.convert(stdErr);
      toLines(text).forEach((line) {
        writelnErr('PUB err | $line');
      });
    });
    _completer.future.timeout(new Duration(seconds: 120), onTimeout: () {
      // called on timeout when future is not yet completed
      var exitCode = p.kill(io.ProcessSignal.SIGKILL);
      writelnErr('kill pub serve - succeeded: $exitCode');
      _pubServeProcess = null;
      _completer.completeError('pub serve launch timed out');
    });
    p.exitCode.then((exitCode) => _pubServeProcess = null);
    return _completer.future;
  });
}
