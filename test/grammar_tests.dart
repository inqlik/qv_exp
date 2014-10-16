library simple_tests;

import 'package:qv_exp/src/parser.dart';
import 'package:qv_exp/src/productions.dart' as p;
import 'package:unittest/unittest.dart';
import 'package:petitparser/petitparser.dart';

var qvs = new QvExpParser();



shouldFail(String source, String production) {
  Result res = qvs.guarded_parse(source, production);
  expect(res.isFailure,isTrue);
}

shouldPass(String source, String production) {
  Result res = qvs.guarded_parse(source,production);
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
    test('Simple function invalid name',() {
      shouldFail('RangeSum1(3,4)',p.start);
    });
    test('Simple function, number without leading zero: if(x > .8, 2)',() {
      shouldPass('if(x > .8, 2)',p.start);
    });

    skip_test('Set expression in function not supporting set expressions: acos({1} 3)',() {
      shouldFail('acos({1} 3)',p.start);
    });
    test('Wrong cardinality in built-in function: acos(1,3)',() {
      shouldFail('acos(1,3)',p.start);
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
    test('Simple set modifier with implicit set identifier',() {
         shouldPass(r'{<OrderDate = DeliveryDate>}',p.setExpression);
     });

    test(r'{$ <Year = {2007, 2008}>}',() {
         shouldPass(r'{$ <Year = {2007, 2008}>}',p.setExpression);
     });
    test(r'{$ <Year={2007,2008},Region={US}>}',() {
         shouldPass(r'{$ <Year={2007,2008},Region={US}>}',p.setExpression);
     });
    test(r'{1<Year={2007,2008},Region={US} >}',() {
         shouldPass(r'{$ <Year={2007,2008},Region={US} >}',p.setExpression);
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

    test(r"""COUNT(DISTINCT {1<_ФлагДействующаяДата=>} Дата)""",() {
         shouldPass(r"""COUNT({1<_ФлагДействующаяДат={1}>} DISTINCT Дата)""",p.expression);
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

    test(r"""sum(DISTINCT {1} TOTAL  Sales)""",() {
         shouldPass(r"""sum(DISTINCT {1} TOTAL  Sales)""",p.expression);
     });
    test(r"""firstsortedvalue ( total <Grp> PurchasedArticle, OrderDate )""",() {
         shouldPass(r"""firstsortedvalue ( total <Grp> PurchasedArticle, OrderDate )""",p.expression);
     });
  });
  
  group('Samples from codebase: ', (){
    test(r"Money(Sum({<_ФлагДействующаяДата={1},ТипДокумента={13},ТипПериода={'Current'}>} Сумма),'# ##0,00')",() {
         shouldPass(r"""Money(Sum({<_ФлагДействующаяДата={1},ТипДокумента={13},ТипПериода={'Current'}>} Сумма),'# ##0,00')""",p.start);
     });
    
    test(r"Some expression from codebase",() {
         shouldPass(r"""if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1},ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= .80 ,'Arrow_S_R.png')""",p.start);
     });
    test(r"$(=Only(OperationType) = 'Sales')",() {
      shouldPass(r"""$(=Only(OperationType) = 'Sales')""",p.start);
    });
    test(r"Num($($(=If(InMonth(Only(ГодМесяц),1313,0),'Оборачиваемость30','ОборачиваемостьМесяц'))))",() {
      shouldPass(r"""Num($($(=If(InMonth(Only(ГодМесяц),1313,0),'Оборачиваемость30','ОборачиваемостьМесяц'))))""",p.start);
    });

    test(r"""If(IsNull(Only({<ГП_$1={$2}>}  _ГП_$1_ФорматМлрд)),'трн','мрд')""",() {
      shouldPass(r"""If(IsNull(Only({<ГП_$1={$2}>}  _ГП_$1_ФорматМлрд)),'трн','мрд')""",p.start);
    });

    test(r"""Only({<ГП_$1={$(=chr(39) & Only({<ГП_ТипПоказателя={ПредГод}>} _ГП_ТипПоказателя) & chr(39))}>}  _ГП_$1)""",() {
      shouldPass(r"""Only({<ГП_$1={$(=chr(39) & Only({<ГП_ТипПоказателя={ПредГод}>} _ГП_ТипПоказателя) & chr(39))}>}  _ГП_$1)""",p.start);
    });

    test(r"""$(=if(_ГруппаПоказателей_План='% изм. План-Факт' or _ГруппаПоказателей_План='% изм. к пред (-1) год' or _ГруппаПоказателей_План='% изм. к пред (-2) год' or _ГруппаПоказателей_План='% изм. к пред (-1) месяц' ,0.8,0))""",() {
      shouldPass(r"""$(=if(_ГруппаПоказателей_План='% изм. План-Факт' or _ГруппаПоказателей_План='% изм. к пред (-1) год' or _ГруппаПоказателей_План='% изм. к пред (-2) год' or _ГруппаПоказателей_План='% изм. к пред (-1) месяц' ,0.8,0))""",p.start);
    });
    test(r"""Num($($(=If(InMonth(Only(ГодМесяц),1313,0),'Оборачиваемость30','ОборачиваемостьМесяц')))""",() {
      shouldPass(r"""Num($($(=If(InMonth(Only(ГодМесяц),1313,0),'Оборачиваемость30','ОборачиваемостьМесяц'))))""",p.start);
    });
    test(r"Some long expression",() {
      var s = r"""
  if (Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')
      /Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') = 0 
      OR IsNull(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/
          Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%')), null(), 'qmem://<builtin>/' & if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= 1.20,'Arrow_N_G.png', if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')
              /Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= 1.051,'Arrow_NE_G.png', 
              if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= 1.05 ,'Arrow_NE_G.png', 
              if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= 1,'Arrow_E_Y.png', 
              if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= .95 ,'Arrow_W_Y.png', 
if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= .801  ,'Arrow_SE_R.png', 
if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= .80 ,'Arrow_S_R.png', 
if(Money(Money(Sum({$<ТипДокумента={2}, ТипПериода={'Current'}>}Сумма)/1000,'# ##0,00')/Money(sum({<ТипДокумента = {2},_ФлагДействующаяДата={1}, ТипПериода={'Год'}>}Сумма)/1000,'# ##0,00'),'# ##0,00%') >= 0 ,'Arrow_S_R.png','Arrow_S_R.png') ))))))))""";
         shouldPass(s,p.start);
     });

    
    });
}