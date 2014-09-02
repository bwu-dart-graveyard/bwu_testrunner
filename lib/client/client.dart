library bwu_testrunner.client.client;

import 'dart:async' as async;
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
  Connection _conn;

  Client(this.grid, this.dataView) {
    _conn = new Connection()
        ..onReceive.listen(_messageHandler)
        ..connect(18070);
    //.then((_) => _conn.requestTestList())
    //.then(_setGridData);
  }

  /// All messages received by the client are passed to this method.
  _messageHandler(Message message) {
    print('Client received: ${message.toJson()}');
    if(message is TestRunProgress) {
      var found = dataView.items.where((e) => e['file'] == message.path && e['testId'] == message.testId);
      if(found.length == 1) {
        var item = found.first;
        var row = dataView.items.indexOf(item);
        print('status: ${message.status}');
        if(message.status != null) item['status'] = message.status;
        if(message.result != null) item['result'] = message.result;
        if(message.logMessage != null) item['message'] += message.logMessage;
        grid.invalidateRow(row);
        grid.render();
      }
    } else if(message is FileTestsResult) {
      message.testResults.forEach((r) {
        var found = dataView.items.where((e) => e['file'] == message.path && e['testId'] == r.id);
        if(found.length == 1) {
          var item = found.first;
          var row = dataView.items.indexOf(item);
          print('status: ${r.passed}');
          item['status'] = r.passed;
          item['result'] = r.result;
          item['startTime'] = r.startTime;
          item['runningTime'] = r.runningTime;
          item['startTime'] = r.startTime;
          item['message'] = item['message'] == null ? r.message : item['message'] + r.message;
          grid.invalidateRow(row);
          grid.render();
        }
      });
      if(message.timedOut) {
        var found = dataView.items.where((e) => e['file'] == message.path);
        found.forEach((item) {
          if(message.testResults.where((tr) => tr.id == item['testId']).length == 0) {
            var row = dataView.items.indexOf(item);
            if(item['result'] == '') {
              item['status'] = 'timeout';
              item['result'] = 'timeout';
              item['message'] = 'timeout';
            }
            grid.invalidateRow(row);
            grid.render();
          }
        });
      }
    } else if(message is TestList) {
      if(message.responseId == null) {
        _setGridData(message);
      }
    }
    grid.invalidateAllRows();
    grid.render();
  }


  /// Add the information from a single test file to the grid.
  _addTestFile(ConsoleTestFile f) {
    f.tests.forEach((t) => _addTest(f.path, null, t));
    f.groups.forEach((g) => _addGroup(f.path, null, g));
    grid.render();
  }

  /// Initialize the grids data from the [TestList] response.
  void _setGridData(TestList response) {
    _conn.testList = response;
    dataView.beginUpdate();
    dataView.items.clear();
    response.consoleTestFiles.forEach((f) {
      _addTestFile(f);
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

    new async.Timer.periodic(new Duration(minutes: 1), (_) {
      if(dataView != null) {
        grid.invalidateAllRows();
        grid.render();
      }
    });
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
      'testId': test.id,
      'type': 'test',
      'file': file,
      'group': parentGroup == null || parentGroup.name == null ? '' : parentGroup.name,
      'test': test.name
    }));
  }


  bool _isWaitingForResponse = false;
  /// Creates a request sent to the server to run all tests.
  void runFileTestsHandler(dom.MouseEvent e) {
    dataView.items.forEach((item) {
      item['prevresult'] = item['result'];
      item['result'] = '';
      item['status'] = '';
      item['runningTime'] = '';
      item['startTime'] = '';
      item['message'] = '';
    });
    grid.invalidateAllRows();
    grid.render();
    var button = e.target as dom.Element;
    if(_isWaitingForResponse) {
      return;
    }
    _isWaitingForResponse = true;
    button.classes.add('running');
    _conn.runAllTestsRequest()
    .then((responses) {
      button.classes.remove('running');
      _isWaitingForResponse = false;
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
