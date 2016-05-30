'''
Created on Jun 4, 2014

@author: stelios
'''
from __future__ import generators    # needs to be at the top of your module

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
import re
import datetime
from time import gmtime,  strftime
import logging
import datetime


def ResultIter(cursor, arraysize=100000):
    'An iterator that uses fetchmany to keep memory usage down'
    while True:
        results = cursor.fetchmany(arraysize)
        if not results:
            break
        for result in results:
            yield result
         
class DBHelper:
    '''
    DBHelper module
    Class to provide necessary database functionality

    University of Edinburgh, WAFU
    @author: Stelios Voutsinas
    
    '''
    
    def __init__(self, db_server, username, password, port="1433", driver="TDS"):
        '''
        Initialise DBHelper class instance
        '''
        self.db_server = db_server
        self.username = username
        self.password = password
        self.port = port
        self.driver = driver
        
    def execute_qry_single_row (self, query, db_name):
        '''
        Execute a query on a database & table, that will return a single row
        '''
        return_val = []
        params = 'DRIVER={' + self.driver + '};SERVER=' + self.db_server + ';Database=' + db_name +';UID=' + self.username + ';PWD=' + self.password +';TDS_Version=8.0;Port='  + self.port + ';'
        cnxn = pyodbc.connect(params)  
        cursor = cnxn.cursor()
        cursor.execute(query)
        row = cursor.fetchone()
        
        if row:
            return_val = row

        cnxn.close()
        
        return return_val
    
    
    def execute_query_multiple_rows(self, query, db_name, limit=None, timeout=None):
        '''
        Execute a query on a database & table that may return any number of rows
        '''
        return_val = []
        params = 'DRIVER={' + self.driver + '};SERVER=' + self.db_server + ';Database=' + db_name +';UID=' + self.username + ';PWD=' + self.password +';TDS_Version=8.0;Port='  + self.port + ';'

        cnxn = pyodbc.connect(params)  

        if timeout!=None:
	    cnxn.timeout=timeout

        cursor = cnxn.cursor()
        cursor.execute(query)

	
	if (limit!=None):
	    rows = cursor.fetchmany(limit)
	else :
	    rows = cursor.fetchall()


        for row in rows:
	    return_val.append(row)


        """
	count = 0
	for row in ResultsIter(cursor):

	    if limit!=None:
                count = count + 1
                if count<= limit:
	            return_val.append(row)
	        else : 
	            break
	    else :
	        return_val.append(row)
	"""
        cnxn.close()
        
        return return_val
        
        
        
    def execute_query_get_cols_rows(self, query, db_name, limit=None, timeout=None):
        '''
        Execute a query on a database & table that may return any number of rows
        '''
        return_val = []
       
        params = 'DRIVER={' + self.driver + '};SERVER=' + self.db_server + ';Database=' + db_name +';UID=' + self.username + ';PWD=' + self.password +';TDS_Version=8.0;Port='  + self.port + ';'
            
        cnxn = pyodbc.connect(params)  

        if timeout!=None:
            cnxn.timeout=timeout
        try:
            cursor = cnxn.cursor()
            cursor.execute(query)

            columns = [column[0] for column in cursor.description]
            return_val.append(columns)
            rowlist=[]

	    if (limit!=None):
                rows = cursor.fetchmany(limit)
            else :
                rows = cursor.fetchall()


            for row in rows:
	        rowlist.append(dict(zip(columns, row)))
	

	    """
	    count = 0        	
	    for row in  ResultIter(cursor):
	        count = count + 1
	        if count<= limit:
	            rowlist.append(dict(zip(columns, row)))
	        else :
	  	    break

     	    """

  	    return_val.append(rowlist) 
 
            cnxn.close()
        except Exception as e:
            cnxn.close()
            raise e
            
        return return_val


    def execute_insert (self, insert_query, db_name, query_parameters):           
        '''
        Execute an insert on a database & table 
        '''
        return_val = []
        params = 'DRIVER={' + self.driver + '};SERVER=' + self.db_server + ';Database=' + db_name +';UID=' + self.username + ';PWD=' + self.password +';TDS_Version=8.0;Port='  + self.port + ';'
        cnxn = pyodbc.connect(params)  
        cursor = cnxn.cursor()
        cursor.execute(insert_query, query_parameters)
        cnxn.commit()
        cnxn.close()
        
    def execute_update(self, update_query, db_name):           
        '''
        Execute an insert on a database & table 
        '''
        return_val = []
        params = 'DRIVER={' + self.driver + '};SERVER=' + self.db_server + ';Database=' + db_name +';UID=' + self.username + ';PWD=' + self.password +';TDS_Version=8.0;Port='  + self.port + ';'
        cnxn = pyodbc.connect(params)  
        cursor = cnxn.cursor()
        cursor.execute(update_query)
        cnxn.commit()
        cnxn.close()        
            
            
class SQLEngine(object):
    '''
    SQLEngine
    Class that handles database interactions
    '''


    def __init__(self, dbserver, dbuser, dbpasswd, dbport='1433', driver='TDS'):
        '''
        Constructor   
           
        :param dbserver:
        :param dbuser:
        :param dbpasswd:
        :param dbport:
        :param driver:
        '''
     
        self.dbserver = dbserver
        self.dbuser = dbuser
        self.dbpasswd = dbpasswd
        self.dbport = dbport
        self.driver = driver
        
    def _getRows(self, query_result):
        '''
        Get rows from a query result array
        
        :param query_result:
        '''
        row_length = -1
        if len(query_result)>=2:
            row_length = len(query_result[1])    
        return row_length
   
    def execute_sql_query(self, query, database, limit=None, timeout=None):
        '''
        Execute an SQL query
        
        @param query: The SQL Query
        @param database: The Database
        '''
        return self._execute_query(query, database, limit, timeout)
    
    
    def execute_update(self, query, database):
        '''
        Execute an SQL Update
        
        @param query: The SQL Query
        @param database: The Database
        '''
        mydb = DBHelper(self.dbserver, self.dbuser, self.dbpasswd, self.dbport, self.driver)
        response = mydb.execute_update(query, database)
        return response
        
        
    def execute_sql_query_get_rows(self, query, database, limit=None, timeout=None):
        '''
        Execute an SQL query
        
        @param query: The SQL Query
        @param database: The Database
        '''
        file_path=''
        now = datetime.datetime.now()
        query_results=[]
        cols = []
        rows = -1
        datatable=[]
        error_code = -1
        
        dthandler = lambda obj: (
            obj.isoformat()
            if isinstance(obj, datetime.datetime) or isinstance(obj, datetime.date) else None)
        
 
        try:
            query_results = self._execute_query_get_cols_rows(query,database, limit, timeout)
        except pyodbc.ProgrammingError, err:
            error_message = repr(err)
            return (-1, error_message)
        except Exception as e:
            if (type(e).__name__=="Timeout"):
                raise e


        return (self._getRows(query_results), "")
    
    def execute_insert (self, qry, database, params):
        '''
        Execute an insert query (qry) against a db 
        
        :param qry:
        :param database:
        :param params:
        '''
        mydb = DBHelper(self.dbserver, self.dbuser, self.dbpasswd, self.dbport, self.driver)
        res = mydb.execute_insert(qry, database, params)
        return res
    

    def _execute_query (self, qry, database, limit=None, timeout=None):
        '''
        Execute a query (qry) against a db and table
        
        :param qry:
        :param database:        
        '''
        mydb = DBHelper(self.dbserver, self.dbuser, self.dbpasswd, self.dbport, self.driver)
        table_data = mydb.execute_query_multiple_rows(qry, database, limit, timeout)
        return table_data
        
        
    def _execute_query_get_cols_rows (self,qry, database, limit=None, timeout=None):
        '''
        Execute a query (qry) against a db and table, the information of which is stored as global variables
        
        :param qry:
        :param database:
        '''
        mydb = DBHelper(self.dbserver,self.dbuser ,self.dbpasswd, self.dbport, self.driver)
        table_data = mydb.execute_query_get_cols_rows(qry, database, limit, timeout)
        return table_data        
          
 
