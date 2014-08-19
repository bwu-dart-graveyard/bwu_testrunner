library bwu_testrunner.result_report;

import 'package:bwu_testrunner/result.dart';

abstract class ResultReport {

  final List<LauncherResult> results;

  ResultReport(this.results);
}