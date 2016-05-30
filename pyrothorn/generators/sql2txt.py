'''
Created on Jun 4, 2014

@author: stelios
'''

import sys, os
srcdir = '../../src/'
configdir = '../../'
testdir = os.path.dirname(__file__)
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(testdir, srcdir)))
sys.path.insert(0, os.path.abspath(os.path.join(testdir, configdir)))
import urllib2
import urllib
import StringIO
import pyodbc
try:
    import simplejson as json
except ImportError:
    import json
import numpy
import re
import logging
import json
import collections


def ResultIter( cursor, arraysize=1000):
    'An iterator that uses fetchmany to keep memory usage down'
    while True:         
        results = cursor.fetchmany(arraysize)
        if not results:
            break
        for result in results:
            yield 	result


    
class Sql2txt(object):
    '''
    SQLEngine
    Class that handles database interactions
    '''

    def __init__(self, dbserver="", dbuser="", dbpasswd="", dbport='1433', driver='MySQL'):
        '''
        Constructor
        '''
        self.dbserver = dbserver
        self.dbuser = dbuser
        self.dbpasswd = dbpasswd
        self.dbport = dbport
        self.driver = driver
   
    def generateTxt(self, query, database, filename):
        '''
        Execute an SQL query
        @param query: The SQL Query
        @param database: The Database
        '''

        connstr = 'DRIVER={' +  self.driver + '};SERVER=' +  self.dbserver + ';UID=' + self.dbuser + ';PWD=' + self.dbpasswd +';DATABASE=' + database +' ;'
        conn = pyodbc.connect(connstr)
        cursor = conn.cursor()
         
        cursor.execute(query)

        #query = """select query from queries where queryrunID like 'ahqBOantQ3e11ZH0wiJkBg' and query not like '%idnum,sourceid%' and test_passed>0  limit 0,1000;"""
        filewriter = open(filename, "w")

        for row in ResultIter( cursor, arraysize=1000):
            print>>filewriter, row[0]
        filewriter.close()
        cursor.close()

