'''
Created on Jun 4, 2014

@author: stelios
'''

import os
import urllib2
import urllib
import StringIO
import time
import xml.dom.minidom
import pyodbc
try:
    import simplejson as json
except ImportError:
    import json
import numpy
from pyrothorn.misc import html_functions
import re
from pyrothorn.misc.string_functions import string_functions
string_functions = string_functions()
import datetime
from pyrothorn.pyroquery.firethorn_config import *
from time import gmtime,  strftime
import logging


class Timeout():
    """Timeout class using ALARM signal."""
    class Timeout(Exception):
        pass

    def __init__(self, sec):
        self.sec = sec

    def __enter__(self):
        signal.signal(signal.SIGALRM, self.raise_timeout)
        signal.alarm(self.sec)

    def __exit__(self, *args):
        signal.alarm(0)    # disable alarm

    def raise_timeout(self, *args):
        raise Timeout.Timeout()




class QueryEngine(object):
    '''
    Query Engine
    
    Used to drive queries through the firethorn service
    '''


    def __init__(self):
        '''
        Constructor
        '''
        self.id = 1
            
            
    def _getRows(self, query_results):
        '''
        Get rows from a query result
        
        :param query_results:
        '''
        rows = json.loads(query_results)
        row_length = -1
        if len(rows)<=1:
            return row_length
        else :
            row_length = len(rows[1])
        return row_length
    
                
    def run_query(self, query=None, query_name="", query_space="", **kwargs):
        '''
        Run a query on a resource
               
        :param query:
        :param query_name:
        :param query_space:
        '''
        
        f=''
        query_space = string_functions.decode(query_space)
        result = ""
        max_size_exceeded = False
        result_adql_table = ""
        query_identity = ""
        datatable = []
        error_message = None

        def read_json(url):
            request2 = urllib2.Request(url, headers={"Accept" : "application/json", "firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
            f_read = urllib2.urlopen(request2)
            query_json = f_read.read()
            f_read.close()
            return query_json        

        try :
            from datetime import datetime
            t = datetime.now()
            if query_name=="":
                query_name = 'query-' + t.strftime("%y%m%d_%H%M%S")
                     
            urlenc = { query_name_param : query_name,  query_param : query, query_mode_param : query_mode}
            data = urllib.urlencode(urlenc)
            request = urllib2.Request(query_space + query_create_uri, data, headers={"Accept" : "application/json", "firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
    
            f = urllib2.urlopen(request)
            query_create_result = json.loads(f.read())
            query_identity = query_create_result["ident"]
            
            # Update query
            urlenc_updt = { query_limit_rows_param : firethorn_limits_rows_absolute, query_limit_time_param : firethorn_limits_time }
            data_updt = urllib.urlencode(urlenc_updt)
            request_updt = urllib2.Request(query_identity, data_updt, headers={"Accept" : "application/json", "firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
            f_updt = urllib2.urlopen(request_updt)
            f_updt.close()

            query_loop_results = self.start_query_loop(query_identity)
            results_adql_url = json.loads(read_json(query_identity)).get("results",None).get("table",None)
            
            if query_loop_results.get("Code", "") !="":
                if query_loop_results.get("Code", "") ==-1:
                    error_message = query_loop_results.get("Content", "Error")
                    logging.info(error_message)
                    return (-1,error_message)
            
            if results_adql_url!=None:
                req_rez_table = urllib2.Request( results_adql_url, headers={"Accept" : "application/json", "firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
                response_rez_table = urllib2.urlopen(req_rez_table) 
                response_rez_table_json = response_rez_table.read()
                result_adql_table = json.loads(response_rez_table_json)["fullname"]
                response_rez_table.close()
             
                if query_loop_results.get("Code", "") == 1:
                    req = urllib2.Request(query_loop_results.get("Content", ""), headers={"firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
                    f = urllib2.urlopen(req)
                    datatable = f.read(MAX_FILE_SIZE) 
                    
                    
                    if len(f.read())>0:
                       logging.info('Query exceeded byte size limit.. ')
                       f.close()
                       return (-1,error_message)   
                   
                    f.close()
            else :
                logging.info('Query returned an error.. ')
                return (-1,error_message)
                
        except Exception as e:
            if (type(e).__name__=="Timeout"):
                raise
            else:
                logging.info('Exception caught in run query:')
                logging.info(e)

            return (-1, e)
        
        if f!='':
            f.close()
            
        return (self._getRows(datatable), "")  
    
    
    
    def start_query_loop(self, url):
        '''
        Start the query loop
        
        @param url: A URL string to be used
        @return: Results of query
        '''
        
        def get_status(url):
            request2 = urllib2.Request(url, headers={"Accept" : "application/json", "firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
            f_read = urllib2.urlopen(request2)
            query_json = f_read.read()
            f_read.close()
            return query_json
        
        max_size_exceeded = False 
        f_read = ""
        return_vot = ''
        delay = INITIAL_DELAY
        start_time = time.time()
        elapsed_time = 0
        query_json = {'syntax' : {'friendly' : 'A problem occurred while running your query', 'status' : 'Error' }}
        
        try:
    
            data = urllib.urlencode({ query_status_update : "COMPLETED", "adql.query.wait.time" : 60000})

            #data = urllib.urlencode({ query_status_update : "RUNNING", 'adql.query.update.delay.every' : '10000', 'adql.query.update.delay.first':'10000', 'adql.query.update.delay.la$
            request = urllib2.Request(url, data, headers={"Accept" : "application/json", "firethorn.auth.identity" : test_email, "firethorn.auth.community" : "public (unknown)"})
            f_update = urllib2.urlopen(request)
            query_json =  json.loads(f_update.read())
            query_status = "QUEUED"
            logging.info("Started query:" + url)


            while query_status=="QUEUED" or query_status=="RUNNING" and elapsed_time<MAX_ELAPSED_TIME:
                query_json = json.loads(get_status(url))
                query_status= query_json["status"]
                time.sleep(delay)
                if elapsed_time>MIN_ELAPSED_TIME_BEFORE_REDUCE and delay<MAX_DELAY:
                    delay = delay + delay
                elapsed_time = int(time.time() - start_time)

            logging.info("Finished query:" + url)

          
            if query_status=="ERROR" or query_status=="FAILED":
                if (query_json["syntax"]["status"]=="PARSE_ERROR"):
                    return {'Code' :-1,  'Content' : 'Query error: ' + query_json["syntax"]["status"] + ' - ' + query_json["syntax"]["friendly"] }
                else:
                    return {'Code' :-1,  'Content' : 'Query error: A problem occurred while running your query'}
            elif query_status=="CANCELLED":
                return {'Code' :1,  'Content' : 'Query error: Query has been canceled' }
            elif query_status=="EDITING":
                return {'Code' :-1,  'Content' :  query_json["syntax"]["status"] + ' - ' + query_json["syntax"]["friendly"] }
            elif query_status=="COMPLETED":
                return {'Code' :1,  'Content' : query_json["results"]["formats"]["datatable"] }
            elif elapsed_time>=MAX_ELAPSED_TIME:
                return {'Code' :-1,  'Content' : 'Query error: Max run time (' + str(MAX_ELAPSED_TIME) + ' seconds) exceeded' }
            else:
                return {'Code' :-1,  'Content' : 'Query error: A problem occurred while running your query' }
            
        
        except Exception as e:
            if (type(e).__name__=="Timeout"):
                raise
            else:
                logging.info("Exception caught while running Firethorn query")
            return {'Code' :-1,  'Content' : 'Query error: A problem occurred while running your query' }

    
    
          
            
