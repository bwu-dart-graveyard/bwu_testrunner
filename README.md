### BWU Testrunner

- run all tests listed in a configuration file
- prints a summary
- returns an exit code != 0 in the case of a test failure to notify other scripts about the result
- runs test using `content_shell --dump-render-tree`
- analyzes the `content_shell` output to recognize failed tests
- can invoke the `$DART_SDK/../chromium/download_contentshell.sh` script 
- loads tests using `pub serve` a file URI or both
- launches `pub serve` automatically
- allows to run only one or several of the test files listed in the configuration
- each test can be configured to be skipped for file URI, `pub serve` or both
- can be invoked by `pub global run`


##Prerequisites
- content_shell needs to be installed

## Usage

- create a config file

```json
{
    "core_ajax_dart": { "doSkipWithoutPubServe": true,  "contentShellOptions": ["--allow-external-pages", "--allow-file-access-from-files"] },
    "core_animated_pages": {},
    "core_collapse": {},
    "core_icon": {"doSkipWithContentShell": true},
    "core_iconset": {"doSkipWithContentShell": true},
    "core_input": {},
    "core_localstorage_dart": {},
    "core_media_query": {"doSkipWithContentShell" : true, "contentShellOptions": ["--disable-popup-blocking"],
        "comment": "TODO(zoechi) resizeTo() doesn't work in contentShell see https://code.google.com/p/dart/issues/detail?id=20273"},
    "core_menu_button": {},
    "core_selection": {},
    "core_selection_multi": {},
    "core_selector_activate_event": {},
    "core_selector_basic": {},
    "core_selector_multi": {},
    "core_shared_lib": {"contentShellOptions": ["--allow-external-pages", "--allow-file-access-from-files"]}
}
```

### Options
```
user@linux ~/source/dart/dart-lang/core-elements
 (testrunner) $ pub global run bwu_testrunner:run -h
current working directory: Directory: '/home/user/source/dart/dart-lang/core-elements'
-p, --port                          The port "pub serve" should serve the content on.
                                    (defaults to "18080")

-c, --config-file                   The JSON file containing a list of tests to run and optional configuration details for each test.
                                    (defaults to "test/run_config.json")

-t, --test-name                     When a test name is provided only this test is run. This option can be added more than once
-d, --dart-sdk-path                 The path to the DART SDK directory.
-o, --contentshell-path             The path of the "content_shell" executable.
-n, --contentshell-download-path    The path of the "content_shell" download archive should be downloaded and extracted to.
-s, --no-pub-serve                  Don't run tests with "pub serve".
                                    (defaults to on)

-f, --no-file                       Don't run tests from files.
                                    (defaults to on)

-h, --help                          Print usage information.
-i, --install-contentshell          Execute "download_contentshell.sh" script if content_shell can not be found.
```

### Example output

```

# ... a lot of test output omitted

CS | All 1 tests passed
CS | #EOF
CS | #EOF
CS err | #EOF
run "content_shell --dump-render-tree --no-sandbox --allow-external-pages --allow-file-access-from-files test/core_shared_lib.html"
CS err | [22622:22622:0813/182232:471972097902:ERROR:browser_main_loop.cc(161)] Running without the SUID sandbox! See https://code.google.com/p/chromium/wiki/LinuxSUIDSandboxDevelopment for more information on developing with the sandbox on.
CS | #READY
CS err | [22646:22646:0813/182233:471973291886:ERROR:renderer_main.cc(227)] Running without renderer sandbox
CS | CONSOLE WARNING: line 12: flushing %s elements
CS | CONSOLE WARNING: line 12: flushing %s elements
CS | Content-Type: text/plain
CS | PASS
CS | 1  PASS    Expectation: core-shared-lib basic.
CS | All 1 tests passed
CS | #EOF
CS | #EOF
CS err | #EOF



----------------- Pub serve tests -----------------
- SKIP core_ajax_dart Test Suite SKIP
  PASS core_animated_pages (all of 1)
  PASS core_collapse (all of 1)
! FAIL core_input 2 FAIL, 3 PASS (of 5)
  PASS core_localstorage_dart (all of 1)
- SKIP core_media_query Test Suite SKIP
! FAIL core_menu_button Test Suite FAIL
  PASS core_selection (all of 1)
  PASS core_selection_multi (all of 1)
  PASS core_selector_activate_event (all of 1)
  PASS core_selector_basic (all of 1)
  PASS core_selector_multi (all of 1)
  PASS core_shared_lib (all of 1)

===================== SUMMARY =====================
FAIL - Test Suite: FAIL 1 PASS 11 (of 13) SKIP 1, Test Case: FAIL 0 PASS 15 (of 15)

------------------- File tests --------------------
- SKIP core_ajax_dart Test Suite SKIP
  PASS core_animated_pages (all of 1)
  PASS core_collapse (all of 1)
! FAIL core_input 2 FAIL, 3 PASS (of 5)
  PASS core_localstorage_dart (all of 1)
- SKIP core_media_query Test Suite SKIP
! FAIL core_menu_button Test Suite FAIL
  PASS core_selection (all of 1)
  PASS core_selection_multi (all of 1)
  PASS core_selector_activate_event (all of 1)
  PASS core_selector_basic (all of 1)
  PASS core_selector_multi (all of 1)
  PASS core_shared_lib (all of 1)

===================== SUMMARY =====================
FAIL - Test Suite: FAIL 1 PASS 10 (of 13) SKIP 2, Test Case: FAIL 2 PASS 12 (of 14)
```

