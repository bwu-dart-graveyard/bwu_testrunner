part of bwu_testrunner.run;

void fail(int exitCode, [String message]) {
  if (message != null) {
    writelnErr(message);
  }
  io.Directory.current = workingDir;
  io.exit(exitCode);
}

List<String> toLines(String text) {
  var lines = text.split('\n');
  if (lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}


void writeErr(text) {
  io.stderr.write('$text');
  //io.stderr.flush();
}

void writelnErr(text) {
  io.stderr.writeln('$text');
  //io.stderr.flush();
}

void write(text) {
  io.stderr.write('$text');
  //io.stderr.flush();
}

void writeln(text) {
  io.stderr.writeln('$text');
  //io.stderr.flush();
}
