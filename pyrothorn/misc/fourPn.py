
from pyparsing import Word, nums, alphas, Combine, oneOf, Optional, \
    opAssoc, operatorPrecedence

class EvalConstant():
    "Class to evaluate a parsed constant or variable"
    def __init__(self, tokens):
        self.value = tokens[0]
    def __call__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_):
        if self.value in vars_:
            return vars_[self.value]
        else:
            try:
                return int( self.value )
            except:
                return float(self.value)

class EvalSignOp():
    "Class to evaluate expressions with a leading + or - sign"
    def __init__(self, tokens):
        self.sign, self.value = tokens[0]
    def __call__(self, tokens):
        self.sign, self.value = tokens[0]
    def eval(self, vars_):
        mult = {'+':1, '-':-1}[self.sign]
        return mult * self.value.eval( vars_ )

def operatorOperands(tokenlist):
    "generator to extract operators and operands in pairs"
    it = iter(tokenlist)
    while 1:
        try:
            o1 = next(it)
            o2 = next(it)
            yield ( o1, o2 )
        except StopIteration:
            break
            
class EvalMultOp():
    "Class to evaluate multiplication and division expressions"
    def __call__(self, tokens):
        self.value = tokens[0]
    def __init__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_ ):
        prod = self.value[0].eval( vars_ )
        for op,val in operatorOperands(self.value[1:]):
            if op == '*':
                prod *= val.eval( vars_ )
            if op == '/':
                prod /= val.eval( vars_ )
            if op == '//':
                prod //= val.eval( vars_ )
            if op == '%':
                prod %= val.eval( vars_ )
        return prod
    
class EvalAddOp():
    "Class to evaluate addition and subtraction expressions"
    def __call__(self, tokens):
        self.value = tokens[0]
    def __init__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_ ):
        sum = self.value[0].eval( vars_ )
        for op,val in operatorOperands(self.value[1:]):
            if op == '+':
                sum += val.eval( vars_ )
            if op == '-':
                sum -= val.eval( vars_ )
        return sum

class EvalComparisonOp():
    "Class to evaluate comparison expressions"
    opMap = {
        "<" : lambda a,b : a < b,
        "<=" : lambda a,b : a <= b,
        ">" : lambda a,b : a > b,
        ">=" : lambda a,b : a >= b,
        "==" : lambda a,b : a == b,
        "!=" : lambda a,b : a != b,
        }
    def __init__(self, tokens):
        self.value = tokens[0]
    def __call__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_ ):
        val1 = self.value[0].eval( vars_ )
        for op,val in operatorOperands(self.value[1:]):
            fn = self.opMap[op]
            val2 = val.eval( vars_ )
            if not fn(val1,val2):
                break
            val1 = val2
        else:
            return True
        return False
    
class Arith():
    # define the parser
    integer = Word(nums)
    real = ( Combine(Word(nums) + Optional("." + Word(nums))
                     + oneOf("E e") + Optional( oneOf('+ -')) + Word(nums))
             | Combine(Word(nums) + "." + Word(nums))
             )
         
    variable = Combine(Word(alphas) + Optional(Word(nums)))
    operand = real | integer | variable

    signop = oneOf('+ -')
    multop = oneOf('* / // %')
    plusop = oneOf('+ -')
    comparisonop = oneOf("< <= > >= == != <>")

    # use parse actions to attach EvalXXX constructors to sub-expressions
    operand.setParseAction(EvalConstant)
    arith_expr = operatorPrecedence(operand,
        [(signop, 1, opAssoc.RIGHT, EvalSignOp),
         (multop, 2, opAssoc.LEFT, EvalMultOp),
         (plusop, 2, opAssoc.LEFT, EvalAddOp),
         (comparisonop, 2, opAssoc.LEFT, EvalComparisonOp),
         ])

    def __init__( self, vars_={} ):
        self.vars_ = vars_
        
    def setvars( self, vars_ ):
        self.vars_ = vars_

    def setvar( self, var, val ):
        self.vars_[ var ] = val

    def eval( self, strExpr ):
        ret = self.arith_expr.parseString( strExpr, parseAll=True)[0]
        result = ret.eval( self.vars_ )
        return result
