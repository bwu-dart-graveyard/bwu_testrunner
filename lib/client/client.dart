library bwu_testrunner.client.client;

import 'dart:html' as dom;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'connection.dart';
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

/**
 * Processes to user input and server messages.
 */
class Client {
  BwuDatagrid grid;

  final List<MapDataItem> data = <MapDataItem>[];
  final DataView dataView;

  int id = 0;
  Connection _conn = new Connection()
      ..onReceive.listen((m) => print('Client received: ${m.toJson()}'));

  Client(this.grid, this.dataView) {
    _conn.connect(18070)
    .then((_) => _conn.requestTestList())
    .then(_setGridData);
  }

  /// Initialize the grids data from the [TestList] response.
  void _setGridData(TestList response) {
    _conn.testList = response;
    dataView.beginUpdate();
    dataView.items.clear();
    response.consoleTestFiles.forEach((f) {
      f.tests.forEach((t) => _addTest(f.path, null, t));
      f.groups.forEach((g) => _addGroup(f.path, null, g));
      grid.render();
    });

    dataView.setItems(data);

    dataView.setGrouping(<GroupingInfo>[new GroupingInfo(
        getter: "file",
        formatter: new GroupTitleFormatter('File'),
        aggregators: [
//        new AvgAggregator("percentComplete"),
//        new SumAggregator("cost")
        ],
//      doAggregateCollapsed: false,
        isLazyTotalsCalculation: true
    ),
    new GroupingInfo(
        getter: "group",
        formatter: new GroupTitleFormatter('Group'),
        aggregators: [
//        new AvgAggregator("percentComplete"),
//        new SumAggregator("cost")
        ],
//      doAggregateCollapsed: false,
        isLazyTotalsCalculation: true
    )
    ]);
    dataView.endUpdate();
    grid.render();
    //print(testList.toJson());
  }

  /// Add the tests of a test group to the grid data.
  void _addGroup(String file, TestGroup parentGroup, TestGroup group, {int indent: 0}) {
    group.tests.forEach((t) => _addTest(file, group, t, indent: indent + 1));
    group.groups.forEach((g) => _addGroup(file, group, g,  indent: indent + 1));
  }

  /// Add a test to the grid data.
  void _addTest(String file, TestGroup parentGroup, Test test, {int indent: 0}) {
    data.add(new MapDataItem({
      'sel': false,
      'id': id++,
      'type': 'test',
      'file': file,
      'group': parentGroup == null || parentGroup.name == null ? '' : parentGroup.name,
      'test': test.name
    }));
  }


  ///
  void runFileTestsHandler(dom.MouseEvent e) {
    (e.target as dom.Element).classes.add('running');
    _conn.runAllTestsRequest()
    .then((responses) {
      (e.target as dom.Element).classes.remove('running');
    });
  }
}

class GroupTitleFormatter extends core.GroupTitleFormatter {
  String name;
  GroupTitleFormatter([this.name = '']);

  @override
  dom.Node call(core.Group group) {

    return new dom.SpanElement()
        ..appendText('${name}: ${group.value} ')
        ..append(
            new dom.SpanElement()
                ..style.color = 'green'
                ..appendText('(${group.count} items)'));
  }
}
