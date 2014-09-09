library bwu_testrunner.client.components.app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'package:polymer/polymer.dart';
import 'package:bwu_testrunner/client/client.dart';
import 'grid_helpers.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {

  AppElement.created() : super.created() {
  }

  Client wsClient;

  @override
  void attached() {
    super.attached();
    grid = $['grid'];

    initGrid()
    .then((_) {

    loadData();
    });

    dom.window.onKeyPress.listen((dom.KeyboardEvent e) {
      switch(new String.fromCharCode(e.charCode)) {
        case ' ':
          wsClient.runFileTestsHandler(null);
          break;
        case 's':
        wsClient.runSelectedTestsHandler(null);
        break;
        case 'a':
        wsClient.runActiveTestsHandler(null);
        break;
      }
    });
  }

  math.Random rnd = new math.Random();

  void loadData() {
    wsClient = new Client(grid, dataView);
  }

  @observable
  String groupingSelection = 'result-first';

  void groupingSelectionChanged(old) {

    switch(groupingSelection) {
      case 'result-first':
        groupByResult(dataView);
        break;
      case 'result-last':
        groupByFileAndTestGroup(dataView);
        break;
    }
  }
}


