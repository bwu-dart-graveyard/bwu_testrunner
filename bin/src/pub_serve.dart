part of bwu_testrunner.run;

async.Future<io.Process> runPubServe() {
  print('launching pub serve --port $pubServePort test');
  return io.Process.start(
      'pub',
      ['serve', '--port', pubServePort.toString(), 'test'],
      workingDirectory: workingDir.path).then((p) {
    var completer = new async.Completer();

    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      toLines(text).forEach((line) {
        print('PUB | $line');
      });


      // 'Build completed' may occur more then once but complete must not be called more than once
      if (!completer.isCompleted &&
      text.contains(new RegExp('Build completed.*'))) {
        completer.complete(p);
      }
    });
    p.stderr.listen((stdErr) {
      var text = UTF8.decoder.convert(stdErr);
      toLines(text).forEach((line) {
        io.stderr.writeln('PUB err | $line');
      });
    });
    completer.future.timeout(new Duration(seconds: 120), onTimeout: () {
      // called on timeout when future is not yet completed
      var exitCode = p.kill(io.ProcessSignal.SIGKILL);
      io.stderr.writeln('kill pub serve - succeeded: $exitCode');
      completer.completeError('pub serve launch timed out');
    });
    return completer.future;
  });
}
