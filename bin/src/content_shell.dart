part of bwu_testrunner.run;

String contentShellPath = "content_shell";
String contentShellDownloadPath;
String contentShellArchivePath;

async.Future<bool> installContentShell() {
  return checkContentShellInPath().then((success) {
    if (success) {
      return true;
    } else {
      return tryFindContentShell().then((success) {
        if (success) {
          // nothing more to do
          return true;
        } else {
          // download content_shell archive
          return downloadContentShell().then((success) {
            if (success) {
              // extract content_shell archive
              return _extractContentShellArchive().then((success) {
                if (success) {
                  return true;
                } else {
                  fail(1);
                }
              });
            } else {
              fail(1);
            }
          });
        }
      });
    }
  });
}

// check if content_shell is available in the path
async.Future<bool> checkContentShellInPath() {
  return io.Process.start(contentShellPath, ['--dump-render-tree']).then((p) {
    return p.exitCode.then((exitCode) => exitCode == 0);
  }).catchError((e) {
    return false;
  });
}

// try to find the content_shell path
async.Future<bool> tryFindContentShell() {
  return io.Process.start('which', ['content_shell']).then((p) {
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
  return io.Process.start(
      path.join(dartSdkPath, '../chromium/download_contentshell.sh'),
      []).then((p) {
    var text;
    //Downloading http://dartlang.org/editor/update/channels/be/38843/dartium/content_shell-linux-x64-release.zip to content_shell-linux-x64-release.zip.
    var regExp = new RegExp(r'^Downloading http://.*?.zip to (.*?\.zip)');
    p.stdout.listen((stdOut) {
      text = UTF8.decoder.convert(stdOut);
      io.stdout.write(text);
      var match = regExp.firstMatch(text);
      if (match != null) {
        contentShellArchivePath = path.join(
            contentShellDownloadPath,
            match.group(1));
      }
    });
    p.stderr.listen((stdErr) {
      io.stderr.write(UTF8.decoder.convert(stdErr));
    });

    return p.exitCode.then((exitCode) {
      if (exitCode == 0) {
        return true;
      } else {
        fail(1, 'Downloading content_shell failed.');
      }
    });
  });
}

// extract downloaded content_shell archive
async.Future<bool> _extractContentShellArchive() {
  return io.Process.start('unzip', [contentShellArchivePath]).then((p) {
    var archivePath;
    var regExp = new RegExp(r'^ extracting: (.*?)/.*');
    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      io.stdout.write(text);
      // Extract concrete archive file name from text like
      var match = regExp.firstMatch(text);
      if (match != null) {
        contentShellPath = path.join(
            io.Directory.current.absolute.path,
            match.group(1),
            'content_shell');

        print('contentShell extracted to: $contentShellPath');
      }
    });
    p.stderr.listen((stdErr) {
      io.stderr.write(UTF8.decoder.convert(stdErr));
    });

    return p.exitCode.then((exitCode) {
      if (exitCode != 0) {
        fail(1, 'Extracting "${contentShellArchivePath}" failed.');
      } else {
        return true;
      }
    });
  });
}
