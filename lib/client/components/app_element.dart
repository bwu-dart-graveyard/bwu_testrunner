library bwu_testrunner.client.components.app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
//import 'package:bwu_datagrid/plugins/cell_selection_model.dart';
import 'package:bwu_datagrid/plugins/row_selection_model.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
import 'package:bwu_datagrid/components/bwu_pager/bwu_pager.dart';
import 'package:bwu_testrunner/client/client.dart';

class SumTotalsFormatter extends core.GroupTotalsFormatter  {

  @override
  void call(dom.HtmlElement target, core.GroupTotals totals, Column columnDef) {
    //target.appendHtml(value);
    double val;
    if(totals['sum'] != null && totals['sum'][columnDef.field] != null) {
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

  List<Column> columns = [
    //new Column(id: "sel", name: "#", field: "num", cssClass: "cell-selection", width: 40, resizable: false, selectable: false, focusable: false),
    new Column(id: "file1", name: "", field: "file1", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
//    new Column(id: "group1", name: "", field: "group1", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
    new Column(id: "test", name: "Test", field: "test", width: 250, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
    new Column(id: "file", name: "File", field: "file", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
    new Column(id: "group", name: "", field: "group", width: 50, minWidth: 50, cssClass: "cell-title", sortable: true /*, editor: new ed.TextEditor()*/),
    new Column(id: "duration", name: "Duration", field: "duration", width: 70, sortable: true, groupTotalsFormatter: new SumTotalsFormatter()),
    new Column(id: "%", name: "% Complete", field: "percentComplete", width: 80, sortable: true /*, formatter: new fm.PercentCompleteBarFormatter(), groupTotalsFormatter: new AvgTotalsFormatter()*/),
    new Column(id: "start", name: "Start", field: "start", minWidth: 60, sortable: true),
    new Column(id: "finish", name: "Finish", field: "finish", minWidth: 60, sortable: true),
    new Column(id: "cost", name: "Cost", field: "cost", width: 90, sortable: true, groupTotalsFormatter: new SumTotalsFormatter()),
    new Column(id: "effort-driven", name: "Effort Driven", width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter(), sortable: true)
  ];

  var gridOptions = new GridOptions(
      enableCellNavigation: true,
      editable: true
  );

  BwuDatagrid grid;
  DataView dataView;
  Client _client;

  String sortcol = "title";
  int sortdir = 1;

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

    grid.setup(dataProvider: dataView, columns: columns, gridOptions: gridOptions).then((_) {
      grid.registerPlugin(new GroupItemMetadataProvider());
      grid.setSelectionModel = new RowSelectionModel();

      ($['pager'] as BwuPager).init(dataView, grid);

      BwuColumnPicker columnPicker = (new dom.Element.tag('bwu-column-picker') as BwuColumnPicker)
          ..columns = columns
          ..grid = grid;
      dom.document.body.append(columnPicker);

      grid.onBwuSort.listen((e) {
        sortdir = e.sortAsc ? 1 : -1;
        sortcol = e.sortColumn.field;

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
      loadData(50);
//      groupByDuration();
      //dataView.endUpdate();

      //$("#gridContainer").resizable();
    });
  }

  math.Random rnd = new math.Random();

  void loadData(int count) {
    _client = new Client(grid, dataView);
  }

  int comparer(DataItem a, DataItem b) {

    var x = a[sortcol], y = b[sortcol];
    if(x == y ) {
      return 0;
    }

    if(x is Comparable) {
      return x.compareTo(y);
    }

    if(y is Comparable) {
      return 1;
    }

    if(x == null && y != null) {
      return -1;
    } else if (x != null && y == null) {
      return 1;
    }

    if(x is bool) {
      return x == true ? 1 : 0;
    }
    return (x == y ? 0 : (x > y ? 1 : -1));
  }
}
