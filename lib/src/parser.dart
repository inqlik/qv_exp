library qv_exp_parser;
import 'package:petitparser/petitparser.dart';

import 'productions.dart' as p;
part 'grammar.dart';


class QvExpParser extends QvExpGrammar {
  String _stripBrakets(String val) {
    if (val.startsWith('[')) {
      val = val.substring(1,val.length-1);  
    }
    return val;
  }
  void initialize() {
    super.initialize();
  }
}
