part of qv_exp_parser;



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


