library bwu_testrunner.content_shell;

import 'dart:async' as async;
import 'dart:convert' show UTF8;
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'util.dart';

bool doInstallContentShell = false;
String contentShellDownloadPath;
String dartSdkPath;

String _contentShellPath = 'content_shell';
String get contentShellPath => _contentShellPath;
String _contentShellArchivePath;
bool _isInstallContentShellDone = false;
bool _isContentShellInstalling = false;
async.Completer _completer;

async.Future<bool> installContentShell() {
  assert(dartSdkPath != null);

  assert(doInstallContentShell != null);

  if(doInstallContentShell) {
    assert(dartSdkPath != null);
    assert(contentShellDownloadPath != null);
  }

  if(_isInstallContentShellDone) {
    return new async.Future.value(true);
  }

  if(_isContentShellInstalling) {
    return _completer.future;
  }

  _completer = new async.Completer();
  _isContentShellInstalling = true;

  return checkContentShellInPath().then((success) {
    if (success) {
      return setDone(isSuccess: true);
    } else {
      return tryFindContentShell().then((success) {
        if (success) {
          return setDone(isSuccess: true);
        } else {
          if(!doInstallContentShell) {
            setDone(isSuccess: false);
            return new async.Future.value(false);
          }

          // download content_shell archive
          return downloadContentShell().then((success) {
            if (success) {
              // extract content_shell archive
              return _extractContentShellArchive().then((success) {
                if (success) {
                  return setDone(isSuccess: true);
                } else {
                  return setDone(isSuccess: false, exitCode: 1);
                }
              });
            } else {
              return setDone(isSuccess: false, exitCode: 1);
            }
          });
        }
      });
    }
  });
}

bool setDone({bool isSuccess: false, int exitCode}) {
  if(exitCode != null) {
    fail(exitCode);
  }
  _isInstallContentShellDone = true;
  _isContentShellInstalling = false;
  _completer.complete(isSuccess);
  return isSuccess;
}

// check if content_shell is available in the path
async.Future<bool> checkContentShellInPath() {
  return io.Process.start(_contentShellPath, ['--dump-render-tree']).then((p) {
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
        _contentShellPath = path;
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
      write(text);
      var match = regExp.firstMatch(text);
      if (match != null) {
        _contentShellArchivePath = path.join(
            contentShellDownloadPath,
            match.group(1));
      }
    });
    p.stderr.listen((stdErr) {
      writeErr(UTF8.decoder.convert(stdErr));
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
  return io.Process.start('unzip', [_contentShellArchivePath]).then((p) {
    var archivePath;
    var regExp = new RegExp(r'(?:\n|^) extracting: (.*?)/.*', multiLine: true);
    p.stdout.listen((stdOut) {
      var text = UTF8.decoder.convert(stdOut);
      write(text);
      // Extract concrete archive file name from text like
      var match = regExp.firstMatch(text);
      if (match != null) {
        _contentShellPath = path.join(
            io.Directory.current.absolute.path,
            match.group(1),
            'content_shell');

        writeln('contentShell extracted to: $_contentShellPath');
      }
    });
    p.stderr.listen((stdErr) {
      writeErr(UTF8.decoder.convert(stdErr));
    });

    return p.exitCode.then((exitCode) {
      if (exitCode != 0) {
        fail(1, 'Extracting "${_contentShellArchivePath}" failed.');
      } else {
        return true;
      }
    });
  });
}
