import 'dart:html';
import 'package:qv_exp/src/parser.dart';
import 'package:petitparser/petitparser.dart' as p; 
void main() {
  querySelector("#parse_expression")
      ..onClick.listen(parseExpression);
}

void parseExpression(MouseEvent event) {
  var expressionText = (querySelector("#formula_text") as TextAreaElement).value;
  var qvs = new QvExpParser();
  var parser = qvs['start'].end();
  p.Result parseResult = new QvExpParser().guarded_parse('start', expressionText);
  String  resultText = 'Expression parsed successfully';
  if (parseResult.isFailure) {
    resultText = 'Error while parsing expression: ${parseResult.message} at position ${parseResult.position}';
  }
  querySelector("#result").text = resultText;
}
