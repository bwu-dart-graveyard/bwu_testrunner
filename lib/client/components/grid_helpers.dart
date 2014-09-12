library bwu_testrunner.client.grid_helpers;

import 'dart:async' as async;
import 'dart:html' as dom;
import 'dart:convert' show HtmlEscape;
import 'package:core_elements/core_icon.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/plugins/checkbox_select_column.dart';
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/plugins/row_selection_model.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
import 'package:intl/intl.dart' as intl;


BwuDatagrid grid;
DataView dataView;

List<Column> columns = [
    //new Column(id: "sel", name: "#", field: "sel", cssClass: "cell-selection", width: 40, resizable: false, sortable: true, focusable: false, editor: new ed.CheckboxEditor(), formatter: new fm.CheckmarkFormatter()),
    new Column(id: "result", name: "Result", field: "result", width: 30, sortable: true, formatter: new ResultFormatter() /*, groupTotalsFormatter: new SumTotalsFormatter()*/),
    new Column(id: "prevresult", name: "Prev. Result", field: "prevresult", width: 30, sortable: true, formatter: new ResultFormatter('prev-result') /*, groupTotalsFormatter: new SumTotalsFormatter()*/),
//      new Column(id: "file1", name: "", field: "file1", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
//    new Column(id: "group1", name: "", field: "group1", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
    new Column(id: "test", name: "Test", field: "test", width: 350, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
    new Column(id: "startTime", name: "Start", field: "startTime", width: 55, sortable: true, formatter: new StartTimeFormatter()),
    new Column(id: "runningTime", name: "Duration", field: "runningTime", width: 55, sortable: true, formatter: new DurationFormatter(), groupTotalsFormatter: new DurationSumTotalsFormatter()),
    new Column(id: "message", name: "Message", field: "message", cssClass: 'allow-tooltip', width: 500, sortable: false, formatter: new MessageFormatter()),
];

class PaperCheckboxSelectionFormatter extends CheckboxSelectionFormatter {
  PaperCheckboxSelectionFormatter(CheckboxSelectColumn selectColumn) : super(selectColumn);
  @override
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target.children.clear();

    if (dataContext != null) {
      var element = (new dom.Element.tag('core-icon') as CoreIcon)
          ..attributes['selectColumn'] = 'true'
          ..attributes['icon'] = 'fa:square-o';
      if(selectColumn.isRowSelected(row)) {
        element
          ..classes.add('selected')
          ..attributes['icon'] = 'fa:check-square-o';
      }
      target.append(element);
    }
  }
}

CheckboxSelectColumn checkboxColumn = new CheckboxSelectColumn(cssClass: 'bwu-datagrid-cell-checkboxsel');

var gridOptions = new GridOptions(
    enableCellNavigation: true,
    editable: true
);

async.Future initGrid() {
  dom.window.onResize.listen(grid.resizeCanvas);

  var groupItemMetadataProvider = new GroupItemMetadataProvider();
  dataView = new DataView(options: new DataViewOptions(
      groupItemMetadataProvider: groupItemMetadataProvider,
      inlineFilters: true
  ));

  checkboxColumn.formatter = new PaperCheckboxSelectionFormatter(checkboxColumn);
  columns.insert(0, checkboxColumn);

  return grid.setup(dataProvider: dataView, columns: columns, gridOptions: gridOptions).then((_) {
    grid.registerPlugin(new GroupItemMetadataProvider());
    grid.setSelectionModel = (new RowSelectionModel(new RowSelectionModelOptions(selectActiveRow: false)));
    grid.registerPlugin(checkboxColumn);

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
  });
}

class GroupTitleFormatter extends core.GroupTitleFormatter {
  String name;
  GroupTitleFormatter([this.name = '']);

  @override
  dom.Node call(core.Group group) {

    return new dom.SpanElement()
      ..appendText('${group.value} ')
      ..append(
        new dom.SpanElement()
          ..style.color = 'gray'
          ..appendText('(${group.count})'));
  }
}

//class SumTotalsFormatter extends core.GroupTotalsFormatter {
//
//  @override
//  void call(dom.HtmlElement target, core.GroupTotals totals, Column columnDef) {
//    //target.appendHtml(value);
//    double val;
//    if (totals['sum'] != null && totals['sum'][columnDef.field] != null) {
//      val = totals['sum'][columnDef.field];
//    }
//    if (val != null) {
//      target.appendHtml("total: ${(val * 100).round() / 100}");
//    } else {
//      target.children.clear();
//    }
//  }
//}

class DurationSumTotalsFormatter extends core.GroupTotalsFormatter {

  @override
  void call(dom.HtmlElement target, core.GroupTotals totals, Column columnDef) {
    //target.appendHtml(value);
    Duration val;
    if (totals['sum'] != null && totals['sum'][columnDef.field] != null) {
      val = totals['sum'][columnDef.field];
    }
    if (val != null) {
      target.appendHtml('${formatDuration(val)}');
    } else {
      target.children.clear();
    }
  }
}

class DurationAggregator extends Aggregator {
  String _field;
  Duration _sum = new Duration(seconds: 0);
  DurationAggregator(this._field);

  @override
  void init() {
    _sum = new Duration(seconds: 0);
  }

  @override
  void accumulate(core.ItemBase item) {
    var val = item[_field];
    if (val != null) {
      if(val is Duration){
        _sum += val;
      }
    }
  }

  @override
  void storeResult(core.GroupTotals groupTotals) {
    if (groupTotals['sum'] == null) {
      groupTotals['sum'] = {};
    }
    groupTotals['sum'][_field] = _sum;
  }
}

String formatDuration(Duration value) {
  var msFormatter = new intl.NumberFormat('000', 'en_US');
  var timePartFormatter = new intl.NumberFormat('00', 'en_US');
  var result;
  if(value == null) {
    return '';
  } else if(value is Duration) {
    int minutes = value.inMinutes.remainder(Duration.MINUTES_PER_HOUR);
    int seconds = value.inSeconds.remainder(Duration.SECONDS_PER_MINUTE);
    int ms = value.inMilliseconds .remainder(Duration.MILLISECONDS_PER_SECOND);
    return '${minutes}:${timePartFormatter.format(seconds)}.${msFormatter.format(ms)}';
  } else {
    return value.toString();
  }
}

class MessageFormatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    String val = value == null ? '' : new HtmlEscape().convert(value.toString());
    var intro = val.length < 150 ? val : val.substring(0,150);
    val = val.replaceAll('\n', '<br>').replaceAll(' ', '&nbsp;');
    if(val.isNotEmpty) {
      target.appendHtml('<core-tooltip position="left"><span tip>${val}</span><span>${intro}</span></core-tooltip>');
    } else {
      target.appendHtml(val);
    }
  }
}

class DurationFormatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target.appendHtml(formatDuration(value));
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

GroupingInfo _groupByFile() {
  return new GroupingInfo(
      getter: "file",
      formatter: new GroupTitleFormatter('File'),
      aggregators: [
//        new AvgAggregator("percentComplete"),
//          new SumAggregator("result"),
          new DurationAggregator("runningTime")
      ],
      doAggregateCollapsed: true,
      isLazyTotalsCalculation: true,
      isDisplayTotalsRow: true,
      doAggregateChildGroups: true
  );
}

GroupingInfo _groupByTestGroup() {
  return new GroupingInfo(
      getter: "group",
      formatter: new GroupTitleFormatter('Group'),
      aggregators: [
//        new AvgAggregator("percentComplete"),
//        new SumAggregator("cost")
          new DurationAggregator("runningTime")
      ],
      doAggregateCollapsed: true,
      isLazyTotalsCalculation: true,
      doAggregateChildGroups: true
  );
}

GroupingInfo _groupByResult() {
  return new GroupingInfo(
      getter: (DataItem item) {
        String result = item['result'];
        String prev = item['prevresult'];
        switch(result) {
          case 'fail':
          case 'error':
          case 'timeout':
            return 'fail';
          case 'pass':
            if(!(prev == 'pass' || prev == null)) {
              return 'flaky';
            }
            return 'pass';
          default:
            return 'no result';
        }
      },
      formatter: new GroupTitleFormatter('Result'),
      aggregators: [
//        new AvgAggregator("percentComplete"),
//        new SumAggregator("cost")
          new DurationAggregator("runningTime")
      ],
      doAggregateCollapsed: true,
      isLazyTotalsCalculation: true,
      doAggregateChildGroups: true
  );
}

void groupByFileAndTestGroup(DataView dataView) {
  dataView.setGrouping(<GroupingInfo>[
    _groupByFile(),
    _groupByTestGroup()
  ]);
}

void groupByResult(DataView dataView) {
  dataView.setGrouping(<GroupingInfo>[
    _groupByResult(),
    _groupByFile(),
    _groupByTestGroup()
  ]);
}

String sortCol = "title";
int sortDir = 1;

// for DataView sort TODO(zoechi) try to make the comparer included in BWU_Datagrid reusable or check if it is
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



