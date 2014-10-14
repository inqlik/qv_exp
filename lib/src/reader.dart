import 'parser.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:petitparser/petitparser.dart' as prs;
import 'package:path/path.dart' as path;
import 'dart:io';
//import 'dart:collection';

class Expression {
  String name;
  String sourceText;
  String expandedText;
  int lineNum;
  String toString() => 'Expression($name, $sourceText)';
  String expressionWithErrorMark(int errorPosition) {
    if (errorPosition != 0) {
      return expandedText.substring(0,errorPosition) + ' ^^^ ' + expandedText.substring(errorPosition);
    }
    return expandedText;
  }

}
class QvError {
  String message;
  Expression expression;
  String expressionWithErrorMark;
  QvError(this.expression,this.message);
  String toString() => 'QvError($message)';
}

class Reader {
  Map<String,Expression> expressions = new Map<String,Expression>();
  QvExpParser parser = new QvExpParser();
  String sourceFileName;
  bool isQdfFormat;
  List<QvError> errors = <QvError>[];
  static final variablePattern = new RegExp(r'\$\(([\wА-Яа-яA-Za-z._0-9]*)\)');
  static final varNameQdfCleanupPattern = new RegExp(r'^\s*(L|S)ET\s+',caseSensitive:false);
  void readFile(String fileName, [String fileContent = null]) {
    String csv  = fileContent;
    sourceFileName = path.normalize(path.absolute(path.dirname(Platform.script.toFilePath()),fileName));
    if (csv == null) {
      if (! new File(sourceFileName).existsSync()) {
         print('File not found: $sourceFileName');
         return;
      } else {
        try {
          csv = new File(sourceFileName).readAsStringSync();
        } catch (exception, stacktrace) {
          print(exception);
          return; 
        }
      }
    }
    readLines(csv);
  }
  void readLines(String csv) {
    var det = new FirstOccurenceSettingsDetector(eols: ['\r\n', '\n']);
    var converter = new CsvToListConverter(csvSettingsDetector: det);
    var lines = converter.convert(csv);
    if (lines.isEmpty) {
      return;
    }
    var header = lines.first;
    isQdfFormat = header.length==4 && 
        header[0] == 'VariableName' && 
        header[1] == 'VariableValue' &&
        header[2] == 'Comments' && 
        header[3] == 'Priority';

    bool isHeader = true;
    int lineNum = 0;
    for (List<String> row in lines) {
      lineNum++;
      if (isHeader) {
        isHeader = false;
        continue;
      }
      var varName = row[0];
      if (isQdfFormat) {
        varName = varName.replaceAll(varNameQdfCleanupPattern, '');
        if (varName.contains('.Label') || varName.contains('.Comment')) {
          continue;
        }
      }
      String varValue = row[1].toString().trim();
      if (varValue[0] == '=') {
        varValue = varValue.substring(1);
      }
      var expression = new Expression()..
          name = varName..
          lineNum = lineNum..
          sourceText = varValue;
      expression.expandedText = expression.sourceText;
      expressions[varName] = expression;
    }
    for (Expression exp in expressions.values) {
      expandExpression(exp);
    }
    for (Expression exp in expressions.values) {
      checkSyntax(exp);
    }

  }
  void addError(Expression expression,String message, [int position = 0]) {
    var errMessage = 'Parse error. File: "${sourceFileName}", line: ${expression.lineNum} col: 1 message: $message';
    var error = new QvError(expression,errMessage);
    error.expressionWithErrorMark = expression.expressionWithErrorMark(position);
    errors.add(error);  
  }
  void expandExpression(Expression expr) {
    var m = variablePattern.firstMatch(expr.expandedText);
    while (m != null) {
      var varName = m.group(1);
      var varValue = '';
      if (expressions.containsKey(varName)) {
        varValue = expressions[varName].expandedText;
      } else {
        addError(expr,'Expression `${expr.name}` use undefined variable `$varName`');
      }
      expr.expandedText = expr.expandedText.replaceAll('\$($varName)',varValue == null ? '' : varValue);
      m = variablePattern.firstMatch(expr.expandedText);
    }
  }
  void checkSyntax(Expression expression) {
    prs.Result result = parser.guarded_parse(expression.expandedText.trim());
    if (result.isFailure) {
      addError(expression,'Syntax error. ${result.message}.', result.position);
    }
  }
  void outputErrors() {
    for (var error in errors) {
      print('------------------------------');
      print(error.expressionWithErrorMark);
      print('>>>>> ' + error.message);
    }
    int exitStatus = 0;
    var parseStatusString = 'successfully';
    if (errors.isNotEmpty) {
      exitStatus = 1;
      parseStatusString = 'Check failed with ${errors.length} errors/warnings';
    }
    print(parseStatusString);
  }
    
}