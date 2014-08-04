part of bwu_testrunner.run;

void fail(int exitCode, [String message]) {
  if (message != null) {
    io.stderr.writeln(message);
  }
  io.Directory.current = workingDir;
  io.stdout.flush();
  io.stderr.flush();
  io.exit(exitCode);
}

List<String> toLines(String text) {
  var lines = text.split('\n');
  if (lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

