library qv_exp_parser;
import 'package:petitparser/petitparser.dart';

import 'productions.dart' as p;
part 'grammar.dart';


class QvDelegateParser extends Parser {

  Parser _delegate;

  QvDelegateParser(this._delegate);

  @override
  Result parseOn(Context context) {
    return _delegate.parseOn(context);
  }

  @override
  List<Parser> get children => [_delegate];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (_delegate == source) {
      _delegate = target;
    }
  }

  @override
  Parser copy() => new QvDelegateParser(_delegate);

}


class QvActionParser extends QvDelegateParser {

  final Function _function;

  QvActionParser(parser, this._function): super(parser);

  @override
  Result parseOn(Context context) {
    int savedPosition = context.position;
    var result = _delegate.parseOn(context);
    if (result.isSuccess) {
      return _function(result, savedPosition);
    } else {
      return result;
    }
  }

  @override
  Parser copy() => new QvActionParser(_delegate, _function);

  @override
  bool equalProperties(QvActionParser other) {
    return super.equalProperties(other) && _function == other._function;
  }

}



class QvExpParser extends QvExpGrammar {
  String _stripBrakets(String val) {
    if (val.startsWith('[')) {
      val = val.substring(1,val.length-1);  
    }
    return val;
  }
  void qv_action(String name, Function function) {
    redef(name, (parser) => new QvActionParser(parser, function));
  }
  Result guarded_parse(String source, [String production = 'start']) {
    Result res;
    var parser = this[production].end();
    try {
      res = parser.parse(source);
    } catch(e) {
      if (e is Result) {
        res = e;
      } else {
        throw e;
      }
    }
    return res;
  }
  Result unguarded_parse(String source, [String production = 'start']) {
    Result res;
    var parser = this[production].end();
    return res = parser.parse(source);
  }

  void initialize() {
    super.initialize();

    qv_action(p.function, (Result result, int savedPosition) {
//      print(result.value);
      String funcName = result.value[0];
      List<String> params = result.value[5];
      if (!BUILT_IN_FUNCTIONS.containsKey(funcName.toUpperCase())) {
        throw result.failure("Unknown buil-in function `$funcName`", savedPosition);
      }
      var funcDesc = BUILT_IN_FUNCTIONS[funcName.toUpperCase()];
//      if (!funcDesc.isSetExpressionPossible) {
//         if (result.value[2] != null) {
//           throw result.failure("Set expression is prohibited in function `$funcName`", savedPosition);
//         }
//      }
      int actualCardinality = 0;
      if (params != null) {
        actualCardinality = params.length;
      }
      if (funcDesc.minCardinality > actualCardinality) {
        throw result.failure("Function `$funcName` should have no less then ${funcDesc.minCardinality} params. Actual param number is ${params.length}", savedPosition);        
      }
      if (funcDesc.maxCardinality < actualCardinality) {
        throw result.failure("Function `$funcName` should have no more then ${funcDesc.maxCardinality} params. Actual param number is ${params.length}", savedPosition);        
      }

      return result;
    });

  }
  
}
