import 'parser.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
//import 'dart:collection';

class Reader {
  QvExpParser parser;
  String sourceFileName;
  List<String> errors = <String>[];
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
    print(lines);
  }
  void addError(String message,[int row = 1 , int col = 1]) {
    var errMessage = 'Parse error. File: "${sourceFileName}", line: $row col: $col message: $message';
    errors.add(errMessage);  
  } 
    
}