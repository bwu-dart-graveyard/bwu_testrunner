library bwu_testrunner.client.components.app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'package:polymer/polymer.dart';
import 'package:intl/intl.dart' as intl;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/plugins/row_selection_model.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
import 'package:bwu_datagrid/components/bwu_pager/bwu_pager.dart';
import 'package:bwu_datagrid/plugins/checkbox_select_column.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_testrunner/client/client.dart';

class SumTotalsFormatter extends core.GroupTotalsFormatter {

  @override
  void call(dom.HtmlElement target, core.GroupTotals totals, Column columnDef) {
    //target.appendHtml(value);
    double val;
    if (totals['sum'] != null && totals['sum'][columnDef.field] != null) {
      val = totals['sum'][columnDef.field];
    }
    if (val != null) {
      target.appendHtml("total: ${(val * 100).round() / 100}");
    } else {
      target.children.clear();
    }
  }
}


@CustomTag('app-element')
class AppElement extends PolymerElement {

  AppElement.created() : super.created() {
  }

  CheckboxSelectColumn checkboxColumn = new CheckboxSelectColumn(cssClass: 'bwu-datagrid-cell-checkboxsel');

  List<Column> columns = [
      //new Column(id: "sel", name: "#", field: "sel", cssClass: "cell-selection", width: 40, resizable: false, sortable: true, focusable: false, editor: new ed.CheckboxEditor(), formatter: new fm.CheckmarkFormatter()),
      new Column(id: "result", name: "Result", field: "result", width: 30, sortable: true, formatter: new ResultFormatter() /*, groupTotalsFormatter: new SumTotalsFormatter()*/),
      new Column(id: "prevresult", name: "Prev. Result", field: "prevresult", width: 30, sortable: true, formatter: new ResultFormatter('prev-result') /*, groupTotalsFormatter: new SumTotalsFormatter()*/),
//      new Column(id: "file1", name: "", field: "file1", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
//    new Column(id: "group1", name: "", field: "group1", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
      new Column(id: "test", name: "Test", field: "test", width: 350, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
      new Column(id: "startTime", name: "Start", field: "startTime", width: 55, sortable: true, formatter: new StartTimeFormatter()),
      new Column(id: "runningTime", name: "Duration", field: "runningTime", width: 55, sortable: true, formatter: new DurationFormatter(), groupTotalsFormatter: new SumTotalsFormatter()),
      new Column(id: "message", name: "Message", field: "message", width: 5000, sortable: false),
  ];

  var gridOptions = new GridOptions(
      enableCellNavigation: true,
      editable: true
  );

  BwuDatagrid grid;
  DataView dataView;
  Client wsClient;

  String sortCol = "title";
  int sortDir = 1;

  @override
  void attached() {
    super.attached();
    grid = $['grid'];

    dom.window.onResize.listen(grid.resizeCanvas);

    var groupItemMetadataProvider = new GroupItemMetadataProvider();
    dataView = new DataView(options: new DataViewOptions(
        groupItemMetadataProvider: groupItemMetadataProvider,
        inlineFilters: true
    ));

    columns.insert(0, checkboxColumn);

    grid.setup(dataProvider: dataView, columns: columns, gridOptions: gridOptions).then((_) {
      grid.registerPlugin(new GroupItemMetadataProvider());
      grid.setSelectionModel = (new RowSelectionModel(new RowSelectionModelOptions(selectActiveRow: false)));
      grid.registerPlugin(checkboxColumn);

      ($['pager'] as BwuPager).init(dataView, grid);

      BwuColumnPicker columnPicker = (new dom.Element.tag('bwu-column-picker') as BwuColumnPicker)
        ..columns = columns
        ..grid = grid;
      dom.document.body.append(columnPicker);

      grid.onBwuSort.listen((e) {
        sortDir = e.sortAsc ? 1 : -1;
        sortCol = e.sortColumn.field;

        // using native sort with comparer
        // preferred method but can be very slow in IE with huge datasets
        dataView.sort(comparer, e.sortAsc);
      });

      // wire up model events to drive the grid
      dataView.onBwuRowCountChanged.listen((e) {
        grid.updateRowCount();
        grid.render();
      });

      dataView.onBwuRowsChanged.listen((e) {
        grid.invalidateRows(e.changedRows);
        grid.render();
      });

      // initialize the model after all the events have been hooked up
      //dataView.beginUpdate();
      //dataView.setFilter(myFilter);
//      dataView.setFilterArgs({
//        'percentComplete': percentCompleteThreshold
//      });
      loadData();
//      groupByDuration();
      //dataView.endUpdate();

      //$("#gridContainer").resizable();
    });
  }

  math.Random rnd = new math.Random();

  void loadData() {
    wsClient = new Client(grid, dataView);
  }

  int comparer(DataItem a, DataItem b) {
    var x = a[sortCol], y = b[sortCol];
    if (x == y) return 0;
    if (x is Comparable) return x.compareTo(y);
    if (y is Comparable) return 1;
    if (x == null && y != null) {
      return -1;
    } else if (x != null && y == null) {
      return 1;
    }
    if (x is bool) return x == true ? 1 : 0;
    return (x == y ? 0 : (x > y ? 1 : -1));
  }
}

class DurationFormatter extends fm.Formatter {
  var msFormatter = new intl.NumberFormat('000', 'en_US');
  var timePartFormatter = new intl.NumberFormat('00', 'en_US');
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    var result;
    if(value == null) {
      result = '';
    } else if(value is Duration) {
      int minutes = value.inMinutes.remainder(Duration.MINUTES_PER_HOUR);
      int seconds = value.inSeconds.remainder(Duration.SECONDS_PER_MINUTE);
      int ms = value.inMilliseconds .remainder(Duration.MILLISECONDS_PER_SECOND);
      result = '${minutes}:${timePartFormatter.format(seconds)}.${msFormatter.format(ms)}';
    } else {
      result = value.toString();
    }
    target.appendHtml(result);
  }
}

class StartTimeFormatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    var result;
    if(value == null) {
      result = '';
    } else if(value is DateTime) {
      var d = new DateTime.now().difference(value as DateTime);
      if(d.inDays > 0) {
        result = '> ${d.inDays} d';
      } else if(d.inHours > 0) {
        result = '> ${d.inHours} h';
      } else if(d.inMinutes > 0) {
        result = '> ${d.inMinutes} min';
      } else {
        result = '> ${d.inSeconds} s';
      }
    } else {
      result = value.toString();
    }
    target.appendHtml(result);
  }
}

class ResultFormatter extends fm.Formatter {
  String cssPrefix;
  ResultFormatter([this.cssPrefix = 'result']) {
    assert(cssPrefix != null);
  }

  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    var result;
    if(value == null) {
      result = '';
    } else {
      var icon;
      var cssClass;
      switch (value) {
        case 'error':
          icon = 'fa:exclamation-circle';
          cssClass = 'error';
          break;
      case 'fail':
          icon = 'fa:exclamation-triangle';
          cssClass = 'fail';
          break;
      case 'pass':
          icon = 'fa:check-square'; // check, check-circle
          cssClass = 'pass';
          break;
      case 'timeout':
          icon = 'fa:clock-o';
          cssClass = 'timeout';
          break;
      }
      result = '<core-icon icon="${icon}" class="test-result ${cssPrefix}-${cssClass}"></core-icon>';
    }
    target.appendHtml(result);
  }
}
