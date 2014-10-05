library simple_tests;

import 'package:qv_exp/src/parser.dart';
import 'package:qv_exp/src/productions.dart' as p;
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

var qvs = new QvExpParser();


Result _parse(String source, String production) {
  var parser = qvs[production].end();
  return parser.parse(source);
}

shouldFail(String source, String production) {
  Result res = _parse(source, production);
  expect(res.isFailure,isTrue);
}

shouldPass(String source, String production) {
  Result res = _parse(source, production);
  String reason = '';
  expect(res.isSuccess,isTrue, reason: '"$source" did not parse as "$production". Message: ${res.message}. ${res.toPositionString()}' );
}

void main() {
  group('Simple expressions', () {
    test('Simple numbers',() {
         shouldPass('1+3',p.start);
     });
    test('Simple expressions with parens',() {
         shouldPass('1+3-( 4 + 2)',p.start);
     });
    test('Simple expressions with parens and fieldNames',() {
         shouldPass('1+field2-( 4 + 2)',p.start);
     });

    test('Simple function',() {
         shouldPass('RangeSum(2,4)',p.start);
     });
    test('Simple function with skipped value',() {
         shouldFail('RangeSum(,4)',p.start);
    });
    skip_test('Simple function invalid name',() {
         shouldFail('RangeSum1(3,4)',p.start);
    });
  });
  group('Set analysis', () {
    test('Simplest',() {
         shouldPass('{1}',p.setExpression);
     });
    test('Non-integer numeric set identifier',() {
         shouldFail('{1.3}',p.setExpression);
     });
    test('Current selection set identifier',() {
         shouldPass(r'{ $  }',p.setExpression);
     });
    test('Bookmark set identifier',() {
         shouldPass(r'{BM01}',p.setExpression);
     });
    test('Alternate state identifier',() {
         shouldPass(r'{[Alternate state1]}',p.setExpression);
     });
    test('Simple set operators',() {
         shouldPass(r'{1-$}',p.setExpression);
     });
    test('Unexistent set operators',() {
         shouldFail(r'{1^$}',p.setExpression);
     });
    test('Simple set operators with bookmark',() {
         shouldPass(r'{1-BM01}',p.setExpression);
     });

    test('Simple set operators with bookmark',() {
         shouldPass(r'{1-BM01-BM02}',p.setExpression);
     });
    solo_test('Set operators with parens',() {
         shouldPass(r'{1-(BM01+BM02)}',p.setExpression);
     });
    
  });

  
}
