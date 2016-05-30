"""
html_functions

Documentation for html_functions module.

Created on May 17, 2011
Web py University of Edinburgh DSc Masters project
@author: Stelios Voutsinas

"""
import math

html_escape_table = {
       "&": "&amp;",
        '"': "&quot;",
        "'": "&apos;",
        ">": "&gt;",
        "<": "&lt;"
        }

  
def escape(text):
    """
    Escape HTML characters
      
    """
    return "".join(html_escape_table.get(c,c) for c in text)


def escape_list(lst):
    """
    Escape HTML characters
      
    """
    def escaper(x):
        lst = []
        for i in x:
            if type(i) is tuple:
                lst.append(escaper(i))
            else:
                if type(i) is float:
                    if math.isnan(float(i)):
                        i = None
                lst.append(i)        
                        
        return lst
    return map(escaper,lst)
                
                
def unescape(s):
    """ 
    Unescape HTML characters
    
    """
    s = s.replace("&lt;", "<")
    s = s.replace("&gt;", ">")
    s = s.replace("&amp;", "&")
    return s

def remove_bold(s):
    """ 
    Unescape HTML characters
    
    """
    s = s.replace("<b", "&lt;b")
    return s
