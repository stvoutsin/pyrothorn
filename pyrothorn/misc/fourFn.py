

from __future__ import division

# Uncomment the line below for readline support on interactive terminal
# import readline  
import re
from pyparsing import Word, alphas, ParseException, Literal, CaselessLiteral \
, Combine, Optional, nums, Or, Forward, ZeroOrMore, StringEnd, alphanums
import math
import traceback
import operator
from decimal import *
# Debugging flag can be set to either "debug_flag=True" or "debug_flag=False"
debug_flag=False

exprStack = []
varStack  = []
variables = {}
getcontext().prec = 18

def pushFirst( str, loc, toks ):
   
    exprStack.append( toks[0] )

def pushFunc( str, loc, toks ):
   
    exprStack.append( toks[0] )
    
    
def assignVar( str, loc, toks ):
    varStack.append( toks[0] )

def pushUMinus( strg, loc, toks ):
    if toks and toks[0]=='-': 
        exprStack.append( 'unary -' )
        #~ exprStack.append( '-1' )
        #~ exprStack.append( '*' )

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
                return int(self.value)
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
        return mult * self.value.eval(vars_)

def operatorOperands(tokenlist):
    "generator to extract operators and operands in pairs"
    it = iter(tokenlist)
    while 1:
        try:
            o1 = next(it)
            o2 = next(it)
            yield (o1, o2)
        except StopIteration:
            break
            
class EvalMultOp():
    "Class to evaluate multiplication and division expressions"
    def __call__(self, tokens):
        self.value = tokens[0]
    def __init__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_):
        prod = self.value[0].eval(vars_)
        for op, val in operatorOperands(self.value[1:]):
            if op == '*':
                prod *= val.eval(vars_)
            if op == '/':
                prod /= val.eval(vars_)
            if op == '//':
                prod //= val.eval(vars_)
            if op == '%':
                prod %= val.eval(vars_)
        return prod
    
class EvalAddOp():
    "Class to evaluate addition and subtraction expressions"
    def __call__(self, tokens):
        self.value = tokens[0]
    def __init__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_):

        sum = self.value[0].eval(vars_)
        for op, val in operatorOperands(self.value[1:]):
            if op == '+':
                sum += val.eval(vars_)
            if op == '-':
                sum -= val.eval(vars_)
        return sum

class EvalComparisonOp():
    "Class to evaluate comparison expressions"
    opMap = {
        "<" : lambda a, b : a < b,
        "<=" : lambda a, b : a <= b,
        ">" : lambda a, b : a > b,
        ">=" : lambda a, b : a >= b,
        "==" : lambda a, b : a == b,
        "!=" : lambda a, b : a != b,
        }
    def __init__(self, tokens):
        self.value = tokens[0]
    def __call__(self, tokens):
        self.value = tokens[0]
    def eval(self, vars_):
        val1 = self.value[0].eval(vars_)
        for op, val in operatorOperands(self.value[1:]):
            fn = self.opMap[op]
            val2 = val.eval(vars_)
            if not fn(val1, val2):
                break
            val1 = val2
        else:
            return True
        return False
    
# Executes functions contained in expressions
class EvalFunction(object):
    pop_ = {}
    def __init__(self, tokens):
        func_ = tokens.funcname
        self.field_ = tokens.arg
    def eval(self):
        # Get the name of the requested field and source db
        # Functions can only be called on dbRef so this always done
        v = self.field_.value

        
        # Evaluate the dbRef (get the value from the db)
        val = self.field_.eval()
        
      
        if self.func_ == 'Root':
            return math.sqrt(val)
        elif self.func == 'abs':
            return abs(val)


# define grammar
e = CaselessLiteral('E')
point = Literal( "." )

plusorminus = Literal('+') | Literal('-')
number = Word(nums) 
integer = Combine( Optional(plusorminus) + number )
floatnumber = Combine( integer +
                       Optional( point + Optional(number) ) +
                       Optional( e + integer )
                     )


plus  = Literal( "+" )
minus = Literal( "-" )
mult  = Literal( "*" )
div   = Literal( "/" )
lpar  = Literal( "(" ).suppress()
rpar  = Literal( ")" ).suppress()
pi    = CaselessLiteral( "PI" )
addop  = plus | minus
multop = mult | div
expop = Literal( "^" )
assign = Literal( "=" )
colon = Literal( ',' )
ident = Word(alphas, alphas+nums+"_$")
fnumber = Combine( Word( "+-"+nums, nums ) + 
                       Optional( point + Optional( Word( nums ) ) ) +
                       Optional( e + Word( "+-"+nums, nums ) ) )

charn = Combine( Word(alphas) + Optional(Word ( nums )))


expr = Forward()


atom = ( Optional("-") + ( pi | e | fnumber | integer | ident + lpar + expr + rpar | charn  ).setParseAction(pushFirst) | 
         ( lpar + expr.suppress() + rpar )
       ).setParseAction(pushUMinus) 
        
factor = Forward()
factor << atom + ZeroOrMore( ( expop + factor ).setParseAction( pushFirst ) )
term = factor + ZeroOrMore( ( multop + factor ).setParseAction( pushFirst ) )
expr << term + ZeroOrMore( ( addop + term ).setParseAction( pushFirst ) )
bnf = expr



# map operator symbols to corresponding arithmetic operations
epsilon = 1e-12
opn = { "+" : operator.add,
        "-" : operator.sub,
        "*" : operator.mul,
        "/" : operator.truediv,
        "^" : operator.pow }

fns  = {"sin" : math.sin,
        "cos" : math.cos,
        "tan" : math.tan,
        "abs" : abs,
        "trunc" : lambda a: int(a),
        "round" : round,
        "sgn" : lambda a: abs(a)>epsilon and cmp(a,0) or 0}



class Arith():
    

    def __init__(self, vars_={}):
        self.vars_ = vars_
        self.variables = vars_

    def setvars(self, vars_):
        self.vars_ = vars_
        self.variables = vars_

    def setvar(self, var, val):
        self.vars_[ var ] = val
        self.variables[var] = val   
        
    def eval(self, strExpr):
        result =""
        if strExpr != '':
        # try parsing the input string
            try:
                L=bnf.parseString(strExpr, parseAll=True)
                
            except Exception as e:
                L=None
           
            if L!=None:
                # calculate result , store a copy in ans , display the result to user
                result=self.evaluateStack(exprStack)
            return result
      
 
    # Recursive function that evaluates the stack
    def evaluateStack(self, s ):
        op = s.pop()
        if op == 'unary -':    
            return self.evaluateStack( s )
        if op in "+-*/^":
            op2 = self.evaluateStack( s )
            op1 = self.evaluateStack( s )
            return float(opn[op]( Decimal(op1) , Decimal(op2) ))
        elif op == "PI":
            return math.pi
        elif op == "E":
            return math.e
        elif op in fns:
            return fns[op]( self.evaluateStack( s ) )
        elif re.search('^[a-zA-Z][a-zA-Z0-9_]*$',op):
            if  self.variables.has_key(op):
                return  self.variables[op]
            else:
                return long( op )
      
        elif op[0].isalpha():
            return 0
        else: 
            return float( op )
        
        
