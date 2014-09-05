library bwu_testrunner.server.logging;

import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';

class LogPrintHandler implements BaseLoggingHandler {

  static void initLogging() {
    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen(new LogPrintHandler());
  }

  LogRecordTransformer transformer;
  String messageFormat;
  String exceptionFormatSuffix;
  String timestampFormat;
  Function printFunc;

  LogPrintHandler({this.messageFormat:
  StringTransformer.DEFAULT_MESSAGE_FORMAT, this.exceptionFormatSuffix:
  StringTransformer.DEFAULT_EXCEPTION_FORMAT, this.timestampFormat:
  StringTransformer.DEFAULT_DATE_TIME_FORMAT, this.printFunc: print}) {
    transformer = new StringTransformer(messageFormat: messageFormat,
    exceptionFormatSuffix: exceptionFormatSuffix, timestampFormat: timestampFormat);
  }

  static const IGNORE_LOGGERS_FINE = const <String>[/*'AuthHandler', 'BinaryDataPacket',
  'ConnectionPool.lifecycle', 'Connection', 'ConnectionPool', 'BufferedSocket',
  'ExecuteQueryHandler', 'PrepareHandler', 'Query', 'QueryStreamHandler'*/];

  static const IGNORE_LOGGER_FINEST = const <String>[/*'Connection', 'Connection.Lifecycle',
  'ConnectionPool', 'Query'*/];

  static const IGNORE_LOGGER_INFO = const <String>[/*'ConnectionPool'*/];

  void call(LogRecord logRecord) {
    if (logRecord.level <= Level.FINE && IGNORE_LOGGERS_FINE.contains(
        logRecord.loggerName)) {
      return;
    }
    if (logRecord.level <= Level.FINEST && IGNORE_LOGGER_FINEST.contains(
        (logRecord.loggerName))) {
      return;
    }
    if (logRecord.level <= Level.INFO && IGNORE_LOGGER_INFO.contains(
        (logRecord.loggerName))) {
      return;
    }
    printFunc(transformer.transform(logRecord));
  }
}
