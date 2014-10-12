part of qv_exp_parser;

class FuncDesc {
  final String name;
  final bool isSetExpressionPossible;
  final int minCardinality;
  final int maxCardinality;
  final bool isDistinctPossible;
  const FuncDesc(this.name,this.isSetExpressionPossible,this.minCardinality,this.maxCardinality,{this.isDistinctPossible: false});
}

  
class QvExpGrammar extends CompositeParser {
  void initialize() {
    _whitespace();
    _number();
    _expression();
    _setExpression();
    _qv();
  }

  void _setExpression() {
    def(p.setExpression,
      _keyword('{').
      seq(ref(p.setEntity)).
      seq(_keyword('}')));
    def(p.setEntity,
      ref(p.setEntityPrimary).separatedBy(ref(p.setOperator), includeSeparators: true));
    def(p.setEntitySimple,
      ref(p.setIdentifier).
      seq(ref(p.setModifier).optional()));
    def(p.setEntityPrimary,
      ref(p.setEntitySimple).or(ref(p.setEntityInParens)));
    def(p.setEntityInParens, _keyword('(').seq(ref(p.setEntity)).seq(_keyword(')')));
    def(p.setIdentifier,
      _keyword(r'$').seq(_keyword('_').optional()).seq(ref(p.integer)).
      or(_keyword('1')).
      or(_keyword(r'$')).
      or(ref(p.identifier)).
      or(ref(p.fieldrefInBrackets)));
    def(p.setOperator,
      _keyword(r'+').
      or(_keyword(r'-')).
      or(_keyword(r'*')).
      or(_keyword(r'/')));
    def(p.setElement,
      ref(p.number).
      or(ref(p.str)).
      or(ref(p.identifier)));
    def(p.setElementList,
        ref(p.setElement).separatedBy(_keyword(','), includeSeparators: false));
    def(p.setElementSet,
      ref(p.setElementFunction).
      or(ref(p.identifier)).
      or(_keyword('{').seq(ref(p.setElementList).optional()).seq(_keyword('}'))));
    def(p.setElementSetInParens, _keyword('(').seq(ref(p.setElementSetExpression)).seq(_keyword(')')));
    def(p.setElementSetPrimary,
      ref(p.setElementSet).or(ref(p.setElementSetInParens)));
    def(p.setElementSetExpression,
      ref(p.setElementSetPrimary).separatedBy(ref(p.setOperator), includeSeparators: true));

    def(p.setFieldSelection,
      ref(p.fieldName).
      seq(_keyword('=').
          or(_keyword('-=')).
          or(_keyword('+=')).
          or(_keyword('*=')).
          or(_keyword('/='))).
      seq(ref(p.setElementSetExpression).optional()).
      or(ref(p.fieldName)));
    def(p.setModifier,
      _keyword('<').
      seq(ref(p.setFieldSelection).separatedBy(_keyword(','), includeSeparators: false)).
      seq(_keyword('>')));
    def(p.setElementFunction,
      _keyword('P').or(_keyword('E')).
      seq(_keyword('(')).
      seq(ref(p.setExpression)).
      seq(ref(p.fieldName).optional()).
      seq(_keyword(')')));
    
  }

  /**
   * Russian letters
   */
  localLetter() => range(1024,1273);
  Parser get trimmer => ref(p.whitespace);
  void _qv() {
    def(p.start, ref(p.expression).end().flatten());
    def(p.stringOrNotSemicolon,
        ref(p.str)
        .or(char(';').neg()).starLazy(char(';')).flatten()
        );
    def(p.params,
        ref(p.expression).separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.totalClause,
        _keyword('TOTAL')
        .seq(ref(p.totalModifier).optional()));
    def(p.totalModifier,
        _keyword('<')
        .seq(ref(p.fieldName).separatedBy(char(',').trim(trimmer), includeSeparators: false))
        .seq(_keyword('>')));
    def(p.paramsOptional,
        ref(p.expression).optional().separatedBy(char(',').trim(trimmer), includeSeparators: false));
    def(p.parens,
        _keyword('(')
            .seq(ref(p.expression))
            .seq(_keyword(')')));
  }
  
  
  /** Defines the whitespace and comments. */
  void _whitespace() {
    
    def(p.whitespace, whitespace()
      .or(ref(p.singeLineComment))
      .or(ref(p.remComment))
      .or(ref(p.multiLineComment)));
    def(p.singeLineComment, string('//')
      .seq(Token.newlineParser().neg().star()));
    def(p.remComment, string('REM')
      .seq(Token.newlineParser().neg().star()));
    def(p.multiLineComment, string('/*')
      .seq(string('*/').neg().star())
      .seq(string('*/')));
  }
 
  _expression() {
    def(p.expression,
        ref(p.binaryExpression).trim(trimmer)
        );   
    def(p.primaryExpression,
        ref(p.str)
        .or(ref(p.unaryExpression))
        .or(ref(p.macroFunction))
        .or(ref(p.function))
        .or(ref(p.number))
        .or(ref(p.fieldName))
        .or(ref(p.parens)));
    def(p.binaryExpression, ref(p.primaryExpression)
        .seq(ref(p.binaryPart).star()).trim(trimmer).flatten());
    def(p.binaryPart, ref(p.binaryOperator)
        .seq(ref(p.primaryExpression)));
    def(p.fieldName,
          _keyword(ref(p.identifier)
          .or(ref(p.fieldrefInBrackets))));
    def(p.identifier,letter().or(anyIn('_%@').or(localLetter()))
        .seq(word().or(anyIn('.%')).or(char('_')).or(localLetter().or(char(r'$'))).plus())
        .or(letter())
//        .seq(whitespace().star().seq(char('(')).not())
        .flatten().trim(trimmer));
    def(p.varName,
        word()
          .or(localLetter())
          .or(anyIn(r'._$#@'))
            .plus().flatten().trim(trimmer)
        );
    def(p.fieldrefInBrackets, _keyword('[')
        .seq(_keyword(']').neg().plus())
        .seq(_keyword(']')).trim(trimmer).flatten());
    def(p.str,
            char("'")
              .seq(char("'").neg().star())
              .seq(char("'"))
            .or(char('"')
                .seq(char('"').neg().star())
                .seq(char('"'))).flatten());
   
    def(p.constant,
        ref(p.number).or(ref(p.str)));
    def(p.function,
        letter()
        .seq(word().or(char('#')).plus()).flatten()
        .trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref(p.setExpression).optional())
        .seq(_keyword('DISTINCT').optional())
        .seq(ref(p.totalClause).optional())
        .seq(ref(p.params).optional())
        .seq(char(')').trim(trimmer)));
    def(p.userFunction,
        word().or(anyIn('._#')).plus().flatten()
        .trim(trimmer)
        .seq(char('(').trim(trimmer))
        .seq(ref(p.paramsOptional).optional())
        .seq(char(')').trim(trimmer)));
    def(p.macroFunction,
            _keyword(r'$(')
                .seq(ref(p.userFunction))
                .seq(_keyword(')').trim(trimmer)));
    def(p.unaryExpression,
        _word('NOT').or(_keyword('-').or(_word('DISTINCT'))).trim(trimmer)
            .seq(ref(p.expression))
            .trim(trimmer).flatten());
    def(p.binaryOperator,
        _word('and')
        .or(_word('or'))
        .or(_word('xor'))
        .or(_word('like'))
        .or(_keyword('<='))
        .or(_keyword('<>'))
        .or(_keyword('!='))
        .or(_keyword('>='))
        .or(anyIn('+-/*<>=&'))
        .or(_word('precedes'))
        .trim(trimmer).flatten()
        );
  }
  
  /** Defines a token parser that ignore case and consumes whitespace. */
  Parser _keyword(dynamic input) {
    var parser = input is Parser ? input :
        input.length == 1 ? char(input) :
        stringIgnoreCase(input);
    return parser.trim(trimmer);
  }
 
  Parser _word(dynamic input) {
    var parser = input is Parser ? input :
        input.length == 1 ? char(input) :
        stringIgnoreCase(input);
    return parser.seq(ref(p.whitespace)).trim(trimmer);
  }
 
  
  void _number() {
    // Implementation borrowed from Smalltalk parser
    def(p.number, char('-').optional()
        .seq(ref(p.positiveNumber)).flatten());
    def(p.positiveNumber, ref(p.scaledDecimal)
        .or(ref(p.float))
        .or(ref(p.integer)));

    def(p.integer, ref(p.radixInteger)
        .or(ref(p.decimalInteger)));
    def(p.decimalInteger, ref(p.digits));
    def(p.digits, digit().plus());
    def(p.radixInteger, ref(p.radixSpecifier)
        .seq(char('r'))
        .seq(ref(p.radixDigits)));
    def(p.radixSpecifier, ref(p.digits));
    def(p.radixDigits, pattern('0-9A-Z').plus());

    def(p.float, ref(p.mantissa)
        .seq(ref(p.exponentLetter)
            .seq(ref(p.exponent))
            .optional()));
    def(p.mantissa, ref(p.digits)
        .seq(char('.'))
        .seq(ref(p.digits)));
    def(p.exponent, char('-')
        .seq(ref(p.decimalInteger)));
    def(p.exponentLetter, pattern('edq'));

    def(p.scaledDecimal, ref(p.scaledMantissa)
        .seq(char('s'))
        .seq(ref(p.fractionalDigits).optional()));
    def(p.scaledMantissa, ref(p.decimalInteger)
        .or(ref(p.mantissa)));
    def(p.fractionalDigits, ref(p.decimalInteger));
  }

}

const Map<String, FuncDesc> BUILT_IN_FUNCTIONS = const <String, FuncDesc>{
  'ACOS':const FuncDesc('ACOS',false,1,1),
  'ADDMONTHS':const FuncDesc('ADDMONTHS',false,2,3),
  'ADDYEARS':const FuncDesc('ADDYEARS',true,0,999),
  'AGE':const FuncDesc('AGE',true,0,999),
  'AGGR':const FuncDesc('AGGR',true,2,999),
  'ALT':const FuncDesc('ALT',true,0,999),
  'APPLYCODEPAGE':const FuncDesc('APPLYCODEPAGE',true,0,999),
  'APPLYMAP':const FuncDesc('APPLYMAP',true,0,999),
  'ARGB':const FuncDesc('ARGB',true,0,999),
  'ASIN':const FuncDesc('ASIN',true,0,999),
  'ATAN':const FuncDesc('ATAN',true,0,999),
  'ATAN2':const FuncDesc('ATAN2',true,0,999),
  'ATTRIBUTE':const FuncDesc('ATTRIBUTE',true,0,999),
  'AUTHOR':const FuncDesc('AUTHOR',true,0,999),
  'AUTONUMBER':const FuncDesc('AUTONUMBER',true,0,999),
  'AUTONUMBERHASH128':const FuncDesc('AUTONUMBERHASH128',true,0,999),
  'AUTONUMBERHASH256':const FuncDesc('AUTONUMBERHASH256',true,0,999),
  'AVG':const FuncDesc('AVG',true,0,999),
  'BITCOUNT':const FuncDesc('BITCOUNT',false,1,1),
  'BLACK':const FuncDesc('BLACK',true,0,999),
  'BLACKANDSCHOLE':const FuncDesc('BLACKANDSCHOLE',true,0,999),
  'BLUE':const FuncDesc('BLUE',true,0,999),
  'BROWN':const FuncDesc('BROWN',true,0,999),
  'CAPITALIZE':const FuncDesc('CAPITALIZE',true,0,999),
  'CEIL':const FuncDesc('CEIL',false,1,3),
  'CHI2TEST_CHI2':const FuncDesc('CHI2TEST_CHI2',true,0,999),
  'CHI2TEST_DF':const FuncDesc('CHI2TEST_DF',true,0,999),
  'CHI2TEST_P':const FuncDesc('CHI2TEST_P',true,0,999),
  'CHIDIST':const FuncDesc('CHIDIST',true,0,999),
  'CHIINV':const FuncDesc('CHIINV',true,0,999),
  'CHR':const FuncDesc('CHR',true,0,999),
  'CLASS':const FuncDesc('CLASS',true,0,999),
  'CLIENTPLATFORM':const FuncDesc('CLIENTPLATFORM',true,0,999),
  'COLOR':const FuncDesc('COLOR',true,0,999),
  'COLORMAPHUE':const FuncDesc('COLORMAPHUE',true,0,999),
  'COLORMAPJET':const FuncDesc('COLORMAPJET',true,0,999),
  'COLORMIX1':const FuncDesc('COLORMIX1',true,0,999),
  'COLORMIX2':const FuncDesc('COLORMIX2',true,0,999),
  'COMBIN':const FuncDesc('COMBIN',false,2,2),
  'COMPUTERNAME':const FuncDesc('COMPUTERNAME',true,0,999),
  'CONCAT':const FuncDesc('CONCAT',true,1,3,isDistinctPossible:true),
  'CONNECTSTRING':const FuncDesc('CONNECTSTRING',true,0,999),
  'CONVERTTOLOCALTIME':const FuncDesc('CONVERTTOLOCALTIME',true,0,999),
  'CORREL':const FuncDesc('CORREL',true,0,999),
  'COS':const FuncDesc('COS',true,0,999),
  'COSH':const FuncDesc('COSH',true,0,999),
  'COUNT':const FuncDesc('COUNT',true,1,1,isDistinctPossible:true),
  'CYAN':const FuncDesc('CYAN',true,0,999),
  'DARKGRAY':const FuncDesc('DARKGRAY',true,0,999),
  'DATE#':const FuncDesc('DATE#',true,0,999),
  'DATE':const FuncDesc('DATE',true,0,999),
  'DAY':const FuncDesc('DAY',true,0,999),
  'DAYEND':const FuncDesc('DAYEND',true,0,999),
  'DAYLIGHTSAVING':const FuncDesc('DAYLIGHTSAVING',true,0,999),
  'DAYNAME':const FuncDesc('DAYNAME',true,0,999),
  'DAYNUMBEROFQUARTER':const FuncDesc('DAYNUMBEROFQUARTER',true,0,999),
  'DAYNUMBEROFYEAR':const FuncDesc('DAYNUMBEROFYEAR',true,0,999),
  'DAYSTART':const FuncDesc('DAYSTART',true,0,999),
  'DIV':const FuncDesc('DIV',false,2,2),
  'DOCUMENTNAME':const FuncDesc('DOCUMENTNAME',true,0,999),
  'DOCUMENTPATH':const FuncDesc('DOCUMENTPATH',true,0,999),
  'DOCUMENTTITLE':const FuncDesc('DOCUMENTTITLE',true,0,999),
  'DUAL':const FuncDesc('DUAL',true,0,999),
  'E':const FuncDesc('E',true,0,999),
  'EVALUATE':const FuncDesc('EVALUATE',true,0,999),
  'EVEN':const FuncDesc('EVEN',false,1,1),
  'EXISTS':const FuncDesc('EXISTS',true,0,999),
  'EXP':const FuncDesc('EXP',true,0,999),
  'FABS':const FuncDesc('FABS',false,1,1),
  'FACT':const FuncDesc('FACT',false,1,1),
  'FALSE':const FuncDesc('FALSE',true,0,999),
  'FDIST':const FuncDesc('FDIST',true,0,999),
  'FIELDINDEX':const FuncDesc('FIELDINDEX',true,0,999),
  'FIELDNAME':const FuncDesc('FIELDNAME',true,0,999),
  'FIELDNUMBER':const FuncDesc('FIELDNUMBER',true,0,999),
  'FIELDVALUE':const FuncDesc('FIELDVALUE',true,0,999),
  'FIELDVALUECOUNT':const FuncDesc('FIELDVALUECOUNT',true,0,999),
  'FILEBASENAME':const FuncDesc('FILEBASENAME',true,0,999),
  'FILEDIR':const FuncDesc('FILEDIR',true,0,999),
  'FILEEXTENSION':const FuncDesc('FILEEXTENSION',true,0,999),
  'FILENAME':const FuncDesc('FILENAME',true,0,999),
  'FILEPATH':const FuncDesc('FILEPATH',true,0,999),
  'FILESIZE':const FuncDesc('FILESIZE',true,0,999),
  'FILETIME':const FuncDesc('FILETIME',true,0,999),
  'FINDONEOF':const FuncDesc('FINDONEOF',true,0,999),
  'FINV':const FuncDesc('FINV',true,0,999),
  'FIRSTSORTEDVALUE':const FuncDesc('FIRSTSORTEDVALUE',true,1,3,isDistinctPossible:true),
  'FIRSTVALUE':const FuncDesc('FIRSTVALUE',true,1,1),
  'FIRSTWORKDATE':const FuncDesc('FIRSTWORKDATE',true,0,999),
  'FLOOR':const FuncDesc('FLOOR',false,1,3),
  'FMOD':const FuncDesc('FMOD',false,2,2),
  'FRAC':const FuncDesc('FRAC',false,1,1),
  'FRACTILE':const FuncDesc('FRACTILE',true,0,999),
  'FV':const FuncDesc('FV',true,0,999),
  'GETEXTENDEDPROPERTY':const FuncDesc('GETEXTENDEDPROPERTY',true,0,999),
  'GETFOLDERPATH':const FuncDesc('GETFOLDERPATH',true,0,999),
  'GETOBJECTFIELD':const FuncDesc('GETOBJECTFIELD',true,0,999),
  'GETREGISTRYSTRING':const FuncDesc('GETREGISTRYSTRING',true,0,999),
  'GMT':const FuncDesc('GMT',true,0,999),
  'GREEN':const FuncDesc('GREEN',true,0,999),
  'HASH128':const FuncDesc('HASH128',true,0,999),
  'HASH160':const FuncDesc('HASH160',true,0,999),
  'HASH256':const FuncDesc('HASH256',true,0,999),
  'HOUR':const FuncDesc('HOUR',true,0,999),
  'HSL':const FuncDesc('HSL',true,0,999),
  'IF':const FuncDesc('IF',true,0,999),
  'INDAY':const FuncDesc('INDAY',true,0,999),
  'INDAYTOTIME':const FuncDesc('INDAYTOTIME',true,0,999),
  'INDEX':const FuncDesc('INDEX',true,0,999),
  'INLUNARWEEK':const FuncDesc('INLUNARWEEK',true,0,999),
  'INLUNARWEEKTODATE':const FuncDesc('INLUNARWEEKTODATE',true,0,999),
  'INMONTH':const FuncDesc('INMONTH',true,0,999),
  'INMONTHS':const FuncDesc('INMONTHS',true,0,999),
  'INMONTHSTODATE':const FuncDesc('INMONTHSTODATE',true,0,999),
  'INMONTHTODATE':const FuncDesc('INMONTHTODATE',true,0,999),
  'INPUT':const FuncDesc('INPUT',true,0,999),
  'INPUTAVG':const FuncDesc('INPUTAVG',true,0,999),
  'INPUTSUM':const FuncDesc('INPUTSUM',true,0,999),
  'INQUARTER':const FuncDesc('INQUARTER',true,0,999),
  'INQUARTERTODATE':const FuncDesc('INQUARTERTODATE',true,0,999),
  'INTERVAL':const FuncDesc('INTERVAL',true,0,999),
  'INTERVAL#':const FuncDesc('INTERVAL#',true,0,999),
  'INWEEK':const FuncDesc('INWEEK',true,0,999),
  'INWEEKTODATE':const FuncDesc('INWEEKTODATE',true,0,999),
  'INYEAR':const FuncDesc('INYEAR',true,0,999),
  'INYEARTODATE':const FuncDesc('INYEARTODATE',true,0,999),
  'IRR':const FuncDesc('IRR',true,0,999),
  'ISNULL':const FuncDesc('ISNULL',true,0,999),
  'ISNUM':const FuncDesc('ISNUM',true,0,999),
  'ISPARTIALRELOAD':const FuncDesc('ISPARTIALRELOAD',true,0,999),
  'ISTEXT':const FuncDesc('ISTEXT',true,0,999),
  'ITERNO':const FuncDesc('ITERNO',true,0,999),
  'KEEPCHAR':const FuncDesc('KEEPCHAR',true,0,999),
  'KURTOSIS':const FuncDesc('KURTOSIS',true,0,999),
  'LASTVALUE':const FuncDesc('LASTVALUE',true,1,1),
  'LASTWORKDATE':const FuncDesc('LASTWORKDATE',true,0,999),
  'LEN':const FuncDesc('LEN',true,0,999),
  'LIGHTBLUE':const FuncDesc('LIGHTBLUE',true,0,999),
  'LIGHTCYAN':const FuncDesc('LIGHTCYAN',true,0,999),
  'LIGHTGRAY':const FuncDesc('LIGHTGRAY',true,0,999),
  'LIGHTGREEN':const FuncDesc('LIGHTGREEN',true,0,999),
  'LIGHTMAGENTA':const FuncDesc('LIGHTMAGENTA',true,0,999),
  'LIGHTRED':const FuncDesc('LIGHTRED',true,0,999),
  'LINEST_B':const FuncDesc('LINEST_B',true,0,999),
  'LINEST_DF':const FuncDesc('LINEST_DF',true,0,999),
  'LINEST_F':const FuncDesc('LINEST_F',true,0,999),
  'LINEST_M':const FuncDesc('LINEST_M',true,0,999),
  'LINEST_R2':const FuncDesc('LINEST_R2',true,0,999),
  'LINEST_SEB':const FuncDesc('LINEST_SEB',true,0,999),
  'LINEST_SEM':const FuncDesc('LINEST_SEM',true,0,999),
  'LINEST_SEY':const FuncDesc('LINEST_SEY',true,0,999),
  'LINEST_SSREG':const FuncDesc('LINEST_SSREG',true,0,999),
  'LINEST_SSRESID':const FuncDesc('LINEST_SSRESID',true,0,999),
  'LOCALTIME':const FuncDesc('LOCALTIME',true,0,999),
  'LOG':const FuncDesc('LOG',true,0,999),
  'LOG10':const FuncDesc('LOG10',true,0,999),
  'LOOKUP':const FuncDesc('LOOKUP',true,0,999),
  'LOWER':const FuncDesc('LOWER',true,0,999),
  'LTRIM':const FuncDesc('LTRIM',true,0,999),
  'LUNARWEEKEND':const FuncDesc('LUNARWEEKEND',true,0,999),
  'LUNARWEEKNAME':const FuncDesc('LUNARWEEKNAME',true,0,999),
  'LUNARWEEKSTART':const FuncDesc('LUNARWEEKSTART',true,0,999),
  'MAGENTA':const FuncDesc('MAGENTA',true,0,999),
  'MAKEDATE':const FuncDesc('MAKEDATE',true,0,999),
  'MAKETIME':const FuncDesc('MAKETIME',true,0,999),
  'MAKEWEEKDATE':const FuncDesc('MAKEWEEKDATE',true,0,999),
  'MAPSUBSTRING':const FuncDesc('MAPSUBSTRING',true,0,999),
  'MATCH':const FuncDesc('MATCH',true,0,999),
  'MAX':const FuncDesc('MAX',true,1,2),
  'MAXSTRING':const FuncDesc('MAXSTRING',true,1,1),
  'MEDIAN':const FuncDesc('MEDIAN',true,0,999),
  'MID':const FuncDesc('MID',true,0,999),
  'MIN':const FuncDesc('MIN',true,1,2),
  'MINSTRING':const FuncDesc('MINSTRING',true,1,1),
  'MINUTE':const FuncDesc('MINUTE',true,0,999),
  'MISSINGCOUNT':const FuncDesc('MISSINGCOUNT',true,1,1,isDistinctPossible:true),
  'MIXMATCH':const FuncDesc('MIXMATCH',true,0,999),
  'MOD':const FuncDesc('MOD',false,2,2),
  'MODE':const FuncDesc('MODE',true,1,1),
  'MONEY':const FuncDesc('MONEY',true,0,999),
  'MONEY#':const FuncDesc('MONEY#',true,0,999),
  'MONTH':const FuncDesc('MONTH',true,0,999),
  'MONTHEND':const FuncDesc('MONTHEND',true,0,999),
  'MONTHNAME':const FuncDesc('MONTHNAME',true,0,999),
  'MONTHSEND':const FuncDesc('MONTHSEND',true,0,999),
  'MONTHSNAME':const FuncDesc('MONTHSNAME',true,0,999),
  'MONTHSSTART':const FuncDesc('MONTHSSTART',true,0,999),
  'MONTHSTART':const FuncDesc('MONTHSTART',true,0,999),
  'MSGBOX':const FuncDesc('MSGBOX',true,0,999),
  'NETWORKDAYS':const FuncDesc('NETWORKDAYS',true,0,999),
  'NOOFFIELDS':const FuncDesc('NOOFFIELDS',true,0,999),
  'NOOFREPORTS':const FuncDesc('NOOFREPORTS',true,0,999),
  'NOOFROWS':const FuncDesc('NOOFROWS',true,0,999),
  'NOOFTABLES':const FuncDesc('NOOFTABLES',true,0,999),
  'NORMDIST':const FuncDesc('NORMDIST',true,0,999),
  'NORMINV':const FuncDesc('NORMINV',true,0,999),
  'NOW':const FuncDesc('NOW',true,0,999),
  'NPER':const FuncDesc('NPER',true,0,999),
  'NPV':const FuncDesc('NPV',true,0,999),
  'NULL':const FuncDesc('NULL',true,0,0),
  'NULLCOUNT':const FuncDesc('NULLCOUNT',true,1,1,isDistinctPossible:true),
  'NUM':const FuncDesc('NUM',true,0,999),
  'NUM#':const FuncDesc('NUM#',true,0,999),
  'NUMAVG':const FuncDesc('NUMAVG',false,1,999),
  'NUMCOUNT':const FuncDesc('NUMCOUNT',false,1,999),
  'NUMERICCOUNT':const FuncDesc('NUMERICCOUNT',true,1,1,isDistinctPossible:true),
  'NUMMAX':const FuncDesc('NUMMAX',false,1,999),
  'NUMMIN':const FuncDesc('NUMMIN',false,1,999),
  'NUMSUM':const FuncDesc('NUMSUM',false,1,999),
  'ODD':const FuncDesc('ODD',false,1,1),
  'ONLY':const FuncDesc('ONLY',true,1,1),
  'ORD':const FuncDesc('ORD',true,0,999),
  'OSUSER':const FuncDesc('OSUSER',true,0,999),
  'PEEK':const FuncDesc('PEEK',true,0,999),
  'PERMUT':const FuncDesc('PERMUT',false,2,2),
  'PI':const FuncDesc('PI',true,0,999),
  'PICK':const FuncDesc('PICK',true,0,999),
  'PMT':const FuncDesc('PMT',true,0,999),
  'POW':const FuncDesc('POW',true,0,999),
  'PREVIOUS':const FuncDesc('PREVIOUS',true,0,999),
  'PURGECHAR':const FuncDesc('PURGECHAR',true,0,999),
  'PV':const FuncDesc('PV',true,0,999),
  'QLIKTECHBLUE':const FuncDesc('QLIKTECHBLUE',true,0,999),
  'QLIKTECHGRAY':const FuncDesc('QLIKTECHGRAY',true,0,999),
  'QLIKVIEWVERSION':const FuncDesc('QLIKVIEWVERSION',true,0,999),
  'QUARTEREND':const FuncDesc('QUARTEREND',true,0,999),
  'QUARTERNAME':const FuncDesc('QUARTERNAME',true,0,999),
  'QUARTERSTART':const FuncDesc('QUARTERSTART',true,0,999),
  'QVDCREATETIME':const FuncDesc('QVDCREATETIME',true,0,999),
  'QVDFIELDNAME':const FuncDesc('QVDFIELDNAME',true,0,999),
  'QVDNOOFFIELDS':const FuncDesc('QVDNOOFFIELDS',true,0,999),
  'QVDNOOFRECORDS':const FuncDesc('QVDNOOFRECORDS',true,0,999),
  'QVDTABLENAME':const FuncDesc('QVDTABLENAME',true,0,999),
  'QVUSER':const FuncDesc('QVUSER',true,0,999),
  'RAND':const FuncDesc('RAND',true,0,999),
  'RANGEAVG':const FuncDesc('RANGEAVG',false,1,999),
  'RANGECORREL':const FuncDesc('RANGECORREL',false,2,999),
  'RANGECOUNT':const FuncDesc('RANGECOUNT',false,1,999),
  'RANGEFRACTILE':const FuncDesc('RANGEFRACTILE',false,1,999),
  'RANGEIRR':const FuncDesc('RANGEIRR',false,1,999),
  'RANGEKURTOSIS':const FuncDesc('RANGEKURTOSIS',false,1,999),
  'RANGEMAX':const FuncDesc('RANGEMAX',false,1,999),
  'RANGEMAXSTRING':const FuncDesc('RANGEMAXSTRING',false,1,999),
  'RANGEMIN':const FuncDesc('RANGEMIN',false,1,999),
  'RANGEMINSTRING':const FuncDesc('RANGEMINSTRING',false,1,999),
  'RANGEMISSINGCOUNT':const FuncDesc('RANGEMISSINGCOUNT',false,1,999),
  'RANGEMODE':const FuncDesc('RANGEMODE',false,1,999),
  'RANGENPV':const FuncDesc('RANGENPV',false,1,999),
  'RANGENULLCOUNT':const FuncDesc('RANGENULLCOUNT',false,1,999),
  'RANGENUMERICCOUNT':const FuncDesc('RANGENUMERICCOUNT',false,1,999),
  'RANGEONLY':const FuncDesc('RANGEONLY',false,1,999),
  'RANGESKEW':const FuncDesc('RANGESKEW',false,1,999),
  'RANGESTDEV':const FuncDesc('RANGESTDEV',false,1,999),
  'RANGESUM':const FuncDesc('RANGESUM',false,1,999),
  'RANGETEXTCOUNT':const FuncDesc('RANGETEXTCOUNT',false,1,999),
  'RANGEXIRR':const FuncDesc('RANGEXIRR',false,1,999),
  'RANGEXNPV':const FuncDesc('RANGEXNPV',false,1,999),
  'RATE':const FuncDesc('RATE',true,0,999),
  'RECNO':const FuncDesc('RECNO',true,0,999),
  'RED':const FuncDesc('RED',true,0,999),
  'RELOADTIME':const FuncDesc('RELOADTIME',true,0,999),
  'REPEAT':const FuncDesc('REPEAT',true,0,999),
  'REPLACE':const FuncDesc('REPLACE',true,0,999),
  'REPORTCOMMENT':const FuncDesc('REPORTCOMMENT',true,0,999),
  'REPORTID':const FuncDesc('REPORTID',true,0,999),
  'REPORTNAME':const FuncDesc('REPORTNAME',true,0,999),
  'REPORTNUMBER':const FuncDesc('REPORTNUMBER',true,0,999),
  'RGB':const FuncDesc('RGB',true,0,999),
  'RIGHT':const FuncDesc('RIGHT',true,0,999),
  'ROUND':const FuncDesc('ROUND',false,1,3),
  'ROWNO':const FuncDesc('ROWNO',true,0,999),
  'RTRIM':const FuncDesc('RTRIM',true,0,999),
  'SECOND':const FuncDesc('SECOND',true,0,999),
  'SETDATEYEAR':const FuncDesc('SETDATEYEAR',true,0,999),
  'SETDATEYEARMONTH':const FuncDesc('SETDATEYEARMONTH',true,0,999),
  'SIGN':const FuncDesc('SIGN',false,1,1),
  'SIN':const FuncDesc('SIN',true,0,999),
  'SINH':const FuncDesc('SINH',true,0,999),
  'SKEW':const FuncDesc('SKEW',true,0,999),
  'SQR':const FuncDesc('SQR',true,0,999),
  'SQRT':const FuncDesc('SQRT',true,0,999),
  'STDEV':const FuncDesc('STDEV',true,0,999),
  'STERR':const FuncDesc('STERR',true,0,999),
  'STEYX':const FuncDesc('STEYX',true,0,999),
  'SUBFIELD|10':const FuncDesc('SUBFIELD|10',true,0,999),
  'SUBSTRINGCOUNT':const FuncDesc('SUBSTRINGCOUNT',true,0,999),
  'SUM':const FuncDesc('SUM',true,1,1,isDistinctPossible:true),
  'SYSCOLOR':const FuncDesc('SYSCOLOR',true,0,999),
  'TABLENAME':const FuncDesc('TABLENAME',true,0,999),
  'TABLENUMBER':const FuncDesc('TABLENUMBER',true,0,999),
  'TAN':const FuncDesc('TAN',true,0,999),
  'TANH':const FuncDesc('TANH',true,0,999),
  'TDIST':const FuncDesc('TDIST',true,0,999),
  'TEXT':const FuncDesc('TEXT',true,0,999),
  'TEXTBETWEEN':const FuncDesc('TEXTBETWEEN',true,0,999),
  'TEXTCOUNT':const FuncDesc('TEXTCOUNT',true,1,1,isDistinctPossible:true),
  'TIME':const FuncDesc('TIME',true,0,999),
  'TIME#':const FuncDesc('TIME#',true,0,999),
  'TIMESTAMP':const FuncDesc('TIMESTAMP',true,0,999),
  'TIMESTAMP#':const FuncDesc('TIMESTAMP#',true,0,999),
  'TIMEZONE':const FuncDesc('TIMEZONE',true,0,999),
  'TINV':const FuncDesc('TINV',true,0,999),
  'TODAY':const FuncDesc('TODAY',true,0,999),
  'TRIM':const FuncDesc('TRIM',true,0,999),
  'true':const FuncDesc('true',true,0,999),
  'TTEST1_CONF':const FuncDesc('TTEST1_CONF',true,0,999),
  'TTEST1_DF':const FuncDesc('TTEST1_DF',true,0,999),
  'TTEST1_DIF':const FuncDesc('TTEST1_DIF',true,0,999),
  'TTEST1_LOWER':const FuncDesc('TTEST1_LOWER',true,0,999),
  'TTEST1_SIG':const FuncDesc('TTEST1_SIG',true,0,999),
  'TTEST1_STERR':const FuncDesc('TTEST1_STERR',true,0,999),
  'TTEST1_T':const FuncDesc('TTEST1_T',true,0,999),
  'TTEST1_UPPER':const FuncDesc('TTEST1_UPPER',true,0,999),
  'TTEST1W_CONF':const FuncDesc('TTEST1W_CONF',true,0,999),
  'TTEST1W_DF':const FuncDesc('TTEST1W_DF',true,0,999),
  'TTEST1W_DIF':const FuncDesc('TTEST1W_DIF',true,0,999),
  'TTEST1W_LOWER':const FuncDesc('TTEST1W_LOWER',true,0,999),
  'TTEST1W_SIG':const FuncDesc('TTEST1W_SIG',true,0,999),
  'TTEST1W_STERR':const FuncDesc('TTEST1W_STERR',true,0,999),
  'TTEST1W_T':const FuncDesc('TTEST1W_T',true,0,999),
  'TTEST1W_UPPER':const FuncDesc('TTEST1W_UPPER',true,0,999),
  'TTEST_CONF':const FuncDesc('TTEST_CONF',true,0,999),
  'TTEST_DF':const FuncDesc('TTEST_DF',true,0,999),
  'TTEST_DIF':const FuncDesc('TTEST_DIF',true,0,999),
  'TTEST_LOWER':const FuncDesc('TTEST_LOWER',true,0,999),
  'TTEST_SIG':const FuncDesc('TTEST_SIG',true,0,999),
  'TTEST_STERR':const FuncDesc('TTEST_STERR',true,0,999),
  'TTEST_T':const FuncDesc('TTEST_T',true,0,999),
  'TTEST_UPPER':const FuncDesc('TTEST_UPPER',true,0,999),
  'TTESTW_CONF':const FuncDesc('TTESTW_CONF',true,0,999),
  'TTESTW_DF':const FuncDesc('TTESTW_DF',true,0,999),
  'TTESTW_DIF':const FuncDesc('TTESTW_DIF',true,0,999),
  'TTESTW_LOWER':const FuncDesc('TTESTW_LOWER',true,0,999),
  'TTESTW_SIG':const FuncDesc('TTESTW_SIG',true,0,999),
  'TTESTW_STERR':const FuncDesc('TTESTW_STERR',true,0,999),
  'TTESTW_T':const FuncDesc('TTESTW_T',true,0,999),
  'TTESTW_UPPER':const FuncDesc('TTESTW_UPPER',true,0,999),
  'UPPER':const FuncDesc('UPPER',true,0,999),
  'UTC':const FuncDesc('UTC',true,0,999),
  'WEEK':const FuncDesc('WEEK',true,0,999),
  'WEEKDAY':const FuncDesc('WEEKDAY',true,0,999),
  'WEEKEND':const FuncDesc('WEEKEND',true,0,999),
  'WEEKNAME':const FuncDesc('WEEKNAME',true,0,999),
  'WEEKSTART':const FuncDesc('WEEKSTART',true,0,999),
  'WEEKYEAR':const FuncDesc('WEEKYEAR',true,0,999),
  'WHITE':const FuncDesc('WHITE',true,0,999),
  'WILDMATCH':const FuncDesc('WILDMATCH',true,0,999),
  'WILDMATCH5':const FuncDesc('WILDMATCH5',true,0,999),
  'XIRR':const FuncDesc('XIRR',true,0,999),
  'XNPV':const FuncDesc('XNPV',true,0,999),
  'YEAR':const FuncDesc('YEAR',true,0,999),
  'YEAR2DATE':const FuncDesc('YEAR2DATE',true,0,999),
  'YEAREND':const FuncDesc('YEAREND',true,0,999),
  'YEARNAME':const FuncDesc('YEARNAME',true,0,999),
  'YEARSTART':const FuncDesc('YEARSTART',true,0,999),
  'YEARTODATE':const FuncDesc('YEARTODATE',true,0,999),
  'YELLOW':const FuncDesc('YELLOW',true,0,999),
  'ZTEST_CONF':const FuncDesc('ZTEST_CONF',true,0,999),
  'ZTEST_DIF':const FuncDesc('ZTEST_DIF',true,0,999),
  'ZTEST_LOWER':const FuncDesc('ZTEST_LOWER',true,0,999),
  'ZTEST_SIG':const FuncDesc('ZTEST_SIG',true,0,999),
  'ZTEST_STERR':const FuncDesc('ZTEST_STERR',true,0,999),
  'ZTEST_UPPER':const FuncDesc('ZTEST_UPPER',true,0,999),
  'ZTEST_Z':const FuncDesc('ZTEST_Z',true,0,999),
  'ZTESTW_CONF':const FuncDesc('ZTESTW_CONF',true,0,999),
  'ZTESTW_DIF':const FuncDesc('ZTESTW_DIF',true,0,999),
  'ZTESTW_LOWER':const FuncDesc('ZTESTW_LOWER',true,0,999),
  'ZTESTW_SIG':const FuncDesc('ZTESTW_SIG',true,0,999),
  'ZTESTW_STERR':const FuncDesc('ZTESTW_STERR',true,0,999),
  'ZTESTW_UPPER':const FuncDesc('ZTESTW_UPPER',true,0,999),
  'ZTESTW_Z':const FuncDesc('ZTESTW_UPPER',true,0,999)  
};


