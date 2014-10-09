library reader_tests;

import 'package:qv_exp/src/reader.dart' as qv;
import 'package:unittest/unittest.dart';
void main() {
  test('test_simplest', () {
    var code = r'''
VariableName,VariableValue,Comments,Priority
SET СуммаПродажи,"Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма),'# ##0,00')",,
SET СуммаПродажи.Comment,Сумма продаж в руб.,,
''';  
    var reader = new qv.Reader()..readFile('CustomVariables.qsv',code);
  });
}