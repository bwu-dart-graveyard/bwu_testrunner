part of bwu_testrunner.run;

String contentShellPath;
String contentShellArchivePath;

async.Future<bool> installContentShell() {
  return checkContentShellInPath()
  .then((success) {
    if(success) {
      return true;
    } else {
      return tryFindContentShell()
      .then((success) {
        if(success) {
          // nothing more to do
          return true;
        } else {
          // download content_shell archive
          return downloadContentShell()
          .then((success) {
            if(success) {
              // extract content_shell archive
              return _extractContentShellArchive()
              .then((success) {
                if(success) {
                  return true;
                } else {
                  io.exit(1);
                }
              });
            } else {
              io.exit(1);
            }
          });
        }
      });
    }
  });
}

// check if content_shell is available in the path
async.Future<bool> checkContentShellInPath() {
  return io.Process.start('content_shell', ['--dump-render-tree'])
  .then((p) {
    return p.exitCode.then((exitCode) => exitCode == 0);
  });
}

// try to find the content_shell path
async.Future<bool> tryFindContentShell() {
  return io.Process.start('which', ['content_shell'])
  .then((p) {
    var path;
    p.stdout.listen((stdOut) {
      path = UTF8.decoder.convert(stdOut);
    });
    return p.exitCode.then((exitCode) {
      if (exitCode == 0) {
        contentShellPath = path;
      } else {
        return false;
      }
    });
  });
}

// execute the content_shell download script
async.Future<bool> downloadContentShell() {
  return io.Process.start('${dartSdkPath}/../chromium/download_contentshell.sh', [])
  .then((p) {
    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      // TODO extract and store ZIP file name
    });
    //Downloading http://dartlang.org/editor/update/channels/be/38843/dartium/content_shell-linux-x64-release.zip to content_shell-linux-x64-release.zip.
    return p.exitCode.then((exitCode) {
      if(exitCode == 0) {
        contentShellArchivePath = text;
        return true;
      } else {
        io.stderr.writeln('Downloading content_shell failed.');
        io.exit(1);
      }
    });
  });
}

// extract downloaded content_shell archive
async.Future<bool> _extractContentShellArchive() {
  io.Process.start('unzip', [zipFileName])
  .then((p) {
    return p.exitCode.then((exitCode) {
      if (exitCode != null) {
        io.stderr.writeln('Extracting "${zipFileName}" failed.');
        io.exit(1);
      } else {
        return true;
      }
    });
  });
}
