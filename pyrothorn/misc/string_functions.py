'''
Created on Nov 7, 2012

@author: stelios
'''
from urllib import quote_plus, unquote, unquote_plus

class string_functions:

    def encode(self, _string):
        return quote_plus(_string.encode("utf8"))
        
        
    def decode(self, _string):
        return unquote_plus(_string.encode("utf8")).decode("utf8")
        