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
    group('Set Identifiers', () {

    test('{1}',() {
         shouldPass('{1}',p.setExpression);
     });
    test('{1.3} (Should fail)',() {
         shouldFail('{1.3}',p.setExpression);
     });
    test(r'{ $  }',() {
         shouldPass(r'{ $  }',p.setExpression);
     });
    test(r'{$_2}',() {
         shouldPass(r'{$_2}',p.setExpression);
     });
    test(r'{$1}',() {
         shouldPass(r'{$1}',p.setExpression);
     });
    skip_test(r'{Document\MyBookmark}',() {
         shouldPass(r'{Document\MyBookmark}',p.setExpression);
     });

    test(r'{BM01}',() {
         shouldPass(r'{BM01}',p.setExpression);
     });
    test(r'{[Alternate state1]}',() {
         shouldPass(r'{[Alternate state1]}',p.setExpression);
     });
    });
    group('Set operators', () {
    test(r'{1-$}',() {
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
    test('Set operators with parens',() {
         shouldPass(r'{1-(BM01+BM02)}',p.setExpression);
     });
    test(r'{$*BM01}',() {
         shouldPass(r'{$*BM01}',p.setExpression);
     });
    skip_test(r'{-($+BM01)}',() {
         shouldPass(r'{-($+BM01)}',p.setExpression);
     });
    });
    test('Set operators with simple set modifier',() {
         shouldPass(r'{1 <OrderDate = DeliveryDate>}',p.setExpression);
     });
    test(r'{$ <Year = {2007, 2008}>}',() {
         shouldPass(r'{$ <Year = {2007, 2008}>}',p.setExpression);
     });
    test(r'{$ <Year={2007,2008},Region={US}>}',() {
         shouldPass(r'{$ <Year={2007,2008},Region={US}>}',p.setExpression);
     });
    test(r"{$ <[Sales Region]={'West coast', 'South America'}>}",() {
         shouldPass(r"{$ <[Sales Region]={'West coast', 'South America'}>}",p.setExpression);
     });
    test(r"""{$ <Ingredient = {"*Garlic*"}>}""",() {
         shouldPass(r"""{$ <Ingredient = {"*Garlic*"}>}""",p.setExpression);
     });

    test(r"""{$<Region = >} """,() {
         shouldPass(r"""{$<Region = >} """,p.setExpression);
     });
    test(r"""{$<Region = {}>} """,() {
         shouldPass(r"""{$<Region = {}>} """,p.setExpression);
     });
    test(r"""{$<Region>} """,() {
         shouldPass(r"""{$<Region>} """,p.setExpression);
     });
    test(r"""{$<Year = {2000}, Region = {US, SE, DE, UK, FR}>} """,() {
         shouldPass(r"""{$<Year = {2000}, Region = {US, SE, DE, UK, FR}>} """,p.setExpression);
     });
    test(r"""{$<Ingredient = {"*garlic*"}>} """,() {
         shouldPass(r"""{$<Ingredient = {"*garlic*"}>} """,p.setExpression);
     });
    group('Set Modifiers with Set Operators', () {
      test(r"""{$<Product = Product + {OurProduct1} - Product>}""",() {
         shouldPass(r"""{$<Product = Product + {OurProduct1} - {OurProduct2}>}""",p.setExpression);
       });
      test(r"""{$<Year = Year + ({"20*",1997} - {2000})>}""",() {
         shouldPass(r"""{$<Year = Year + ({"20*",1997} - {2000})>}""",p.setExpression);
       });
      test(r"""{$<Year = (Year + {"20*",1997}) - {2000} >}""",() {
         shouldPass(r"""{$<Year = (Year + {"20*",1997}) - {2000} >}""",p.setExpression);
       });
      test(r"""{$<Year = {"*"} - {2000}, Product = {"*bearing*"} >} """,() {
         shouldPass(r"""{$<Year = {"*"} - {2000}, Product = {"*bearing*"} >} """,p.setExpression);
       });

    });

    group('Set Modifiers Using Assignments with Implicit Set Operators', () {
      test(r"""{$<Product += {OurProduct1, OurProduct2} >}""",() {
         shouldPass(r"""{$<Product += {OurProduct1, OurProduct2} >}""",p.setExpression);
       });
      test(r"""{$<Year += {"20*",1997} - {2000} >} """,() {
         shouldPass(r"""{$<Year += {"20*",1997} - {2000} >} """,p.setExpression);
       });
      test(r"""{$<Product *= {OurProduct1} >} """,() {
         shouldPass(r"""{$<Product *= {OurProduct1} >} """,p.setExpression);
       });

    });

    group('Set Modifiers with Implicit Field Value Definitions', () {
      test(r"""{$<Customer = P({1<Product={'Shoe'}>} Customer)>}""",() {
         shouldPass(r"""{$<Customer = P({1<Product={'Shoe'}>} Customer)>}""",p.setExpression);
       });
      test(r"""{$<Customer = P({1<Product={'Shoe'}>})>}""",() {
         shouldPass(r"""{$<Customer = P({1<Product={'Shoe'}>})>}""",p.setExpression);
       });
      test(r"""{$<Customer = P({1<Product={'Shoe'}>})>}""",() {
         shouldPass(r"""{$<Customer = P({1<Product={'Shoe'}>})>}""",p.setExpression);
       });
      test(r"""{$<Customer = P({1<Product={Shoe}>} Supplier)>}""",() {
         shouldPass(r"""{$<Customer = P({1<Product={Shoe}>} Supplier)>}""",p.setExpression);
       });
      test(r"""{$<Customer = E({1<Product={'Shoe'}>})>} """,() {
         shouldPass(r"""{$<Customer = E({1<Product={'Shoe'}>})>}""",p.setExpression);
       });

    });  
  });
  group('Functions: ', (){
    test(r"""count({$} DISTINCT [Invoice Number])""",() {
         shouldPass(r"""count({$} DISTINCT [Invoice Number])""",p.expression);
     });
    test(r"""count({State1} DISTINCT [Invoice Number])""",() {
         shouldPass(r"""count({State1} DISTINCT [Invoice Number])""",p.expression);
     });
    skip_test(r"""count({$<[Invoice Number] = p({$} [Invoice Number]) * p({State1} [Invoice Number])>} DISTINCT
[Invoice Number])""",() {
         shouldPass(r"""count({$<[Invoice Number] = p({$} [Invoice Number]) * p({State1} [Invoice Number])>} DISTINCT [Invoice Number])""",p.expression);
     });
    test(r"""sum(Price*Quantity)""",() {
         shouldPass(r"""sum(Price*Quantity)""",p.expression);
     });

    test(r"""sum(distinct Price)""",() {
         shouldPass(r"""sum(distinct Price)""",p.expression);
     });
    test(r"""sum(Sales)/sum(total Sales) """,() {
         shouldPass(r"""sum(Sales)/sum(total Sales) """,p.expression);
     });
    test(r"""sum(Sales)/sum(total <Month> Sales) """,() {
         shouldPass(r"""sum(Sales)/sum(total <Month> Sales) """,p.expression);
     });
    test(r"""sum(Sales)/sum(total <Month,Grp> Sales)""",() {
         shouldPass(r"""sum(Sales)/sum(total <Month,Grp> Sales)""",p.expression);
     });
    test(r"""sum(Sales)/sum(total <Qtr,Month,Week> Sales) """,() {
         shouldPass(r"""sum(Sales)/sum(total <Qtr,Month,Week>Sales) """,p.expression);
     });
    test(r"""sum(Sales ASDFASDFA ASDFASDF) - should fail""",() {
         shouldFail(r"""sum(Sales ASDFASDFA ASDFASDF)""",p.expression);
     });
    test(r"""sum(Sales ASDFASDFA) - should fail""",() {
         shouldFail(r"""sum(Sales ASDFASDFA)""",p.expression);
     });
    test(r"""sum(Sales DISTINCT) - should fail""",() {
         shouldFail(r"""sum(Sales DISTINCT)""",p.expression);
     });

    test(r"""sum(DISTINCT {1} TOTAL  Sales) - should fail""",() {
         shouldFail(r"""sum(DISTINCT {1} TOTAL  Sales)""",p.expression);
     });
    test(r"""firstsortedvalue ( total <Grp> PurchasedArticle, OrderDate )""",() {
         shouldPass(r"""firstsortedvalue ( total <Grp> PurchasedArticle, OrderDate )""",p.expression);
     });
    
    
  });
  
}
