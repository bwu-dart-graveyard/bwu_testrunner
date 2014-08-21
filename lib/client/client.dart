library bwu_testrunner.client.client;

import 'dart:html' as dom;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'connection.dart';
import 'package:bwu_testrunner/shared/message.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

class Client {
  BwuDatagrid grid;

  final List<MapDataItem> data = <MapDataItem>[];
  final DataView dataView;

  int id = 0;
  Connection _conn = new Connection();

  Client(this.grid, this.dataView) {
    _conn.connect(18070)
    .then((_) => _conn.requestTestList())
    .then((testList) {
      dataView.beginUpdate();
      (testList as TestList).consoleTestfiles.forEach((f) {
        f.tests.forEach((t) => addTest(f.path, null, t));
        f.groups.forEach((g) => addGroup(f.path, null, g));
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
        isLazyTotalsCalculation: true,
        comparer: testComparer //(core.Group a, core.Group b) => a.groupingKey.compareTo(b.groupingKey)
      ),
      new GroupingInfo(
        getter: "group",
        formatter: new GroupTitleFormatter('Group'),
        aggregators: [
//        new AvgAggregator("percentComplete"),
//        new SumAggregator("cost")
        ],
//      doAggregateCollapsed: false,
        isLazyTotalsCalculation: true,
        comparer: testComparer // (core.Group a, core.Group b) => a.groupingKey.compareTo(b.groupingKey)
      )
      ]);
      dataView.endUpdate();
      grid.render();
      //print(testList.toJson());
    });
  }

  void addGroup(String file, TestGroup parentGroup, TestGroup group, {int indent: 0}) {
    group.tests.forEach((t) => addTest(file, group, t, indent: indent + 1));
    group.groups.forEach((g) => addGroup(file, group, g,  indent: indent + 1));
  }

  void addTest(String file, TestGroup parentGroup, Test test, {int indent: 0}) {
    data.add(new MapDataItem({
      'id': id++,
      'type': 'test',
      'file': file,
      'group': parentGroup == null || parentGroup.name == null ? '' : parentGroup.name,
      'test': test.name
    }));
  }

  int testComparer(core.Group a, core.Group b) {
    return (a.value as String).compareTo(b.value);
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