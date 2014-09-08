library bwu_testrunner.client.grid_helpers;

import 'dart:html' as dom;
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:intl/intl.dart' as intl;

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

class SumAggregator extends Aggregator {
  String _field;
  double _sum = 0.0;
  SumAggregator(this._field);

  @override
  void accumulate(core.ItemBase item) {
    var val = item[_field];
    if (val != null) {
      if(val is String && val.isNotEmpty){
        _sum += double.parse(val);
      } else if(val is num) {
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

