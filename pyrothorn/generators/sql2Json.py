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
import config

def ResultIter( cursor, arraysize=1000):
    'An iterator that uses fetchmany to keep memory usage down'
    while True:         
        results = cursor.fetchmany(arraysize)
        if not results:
            break
        for result in results:
            yield result


    
class Sql2Json(object):
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
   
    def generateJson(self, database, table):
        '''
        Execute an SQL query
        @param query: The SQL Query
        @param database: The Database
        '''

        connstr = 'DRIVER={' +  self.driver + '};SERVER=' +  self.dbserver + ';UID=' + self.dbuser + ';PWD=' + self.dbpasswd +';DATABASE=' + database +' ;'
        conn = pyodbc.connect(connstr)
        cursor = conn.cursor()
         
        cursor.execute("""
                    SELECT *
                    FROM """ + table)
        # rows = cursor.fetchall()
    
        # Convert query to objects of key-value pairs
        failed_list = []
        summary = [] 
        objects_list = []
        sum = collections.OrderedDict()
        total_failures = 0
        total_firethorn_duration = 0
        total_sql_duration = 0
        failed_queries_per_run = collections.OrderedDict()
        try:
            for row in ResultIter(cursor, arraysize=1000):
                # for row in rows:
            
                d = collections.OrderedDict()
                d['queryid'] = row.queryid
                d['queryrunID'] = row.queryrunID
                d['query_timestamp'] = row.query_timestamp
                d['query'] = row.query.decode("ISO-8859-1")

                d['direct_sql_rows'] = row.direct_sql_rows
                d['firethorn_sql_rows'] = row.firethorn_sql_rows
                d['firethorn_duration'] = row.firethorn_duration
                d['sql_duration'] = row.sql_duration
                d['test_passed'] = row.test_passed
                d['firethorn_version'] = row.firethorn_version
                d['firethorn_error_message'] = row.firethorn_error_message
                d['sql_error_message'] = row.sql_error_message
                d['query_hash'] = row.query_hash
                d['java_version'] = row.java_version
                d['sys_timestamp'] = row.sys_timestamp
                d['firethorn_changeset'] = row.firethorn_changeset
                d['sys_platform'] = row.sys_platform

                objects_list.append(d)
                queryrun = row.queryrunID

                if (row.queryrunID=="" or row.queryrunID==None):
                    queryrun  = "No ID"
                    
                if sum.get(queryrun,None)==None:
                    sum[queryrun] = {}
                    sum[queryrun]['total_queries_run'] = 0
                    sum[queryrun]['total_failed'] = 0
                    sum[queryrun]['firethorn_version'] = row.firethorn_version
                    sum[queryrun]['total_firethorn_querytime'] = 0
                    sum[queryrun]['total_sql_querytime'] = 0
                    sum[queryrun]['java_version'] = row.java_version
                    sum[queryrun]['sys_timestamp'] = row.sys_timestamp
                    sum[queryrun]['firethorn_changeset'] = row.firethorn_changeset
                    sum[queryrun]['sys_platform'] = row.sys_platform


                failed_queries_per_run[queryrun] = []

                sum[queryrun]['total_queries_run'] = sum[queryrun]['total_queries_run'] + 1
                sum[queryrun]['total_sql_querytime'] = float(sum[queryrun]['total_sql_querytime']) + float(row.sql_duration)
                sum[queryrun]['total_firethorn_querytime'] = float(sum[queryrun]['total_firethorn_querytime']) + float(row.firethorn_duration)
                sum[queryrun]['query_timestamp'] = row.query_timestamp

                if row.test_passed!=1:
                    failed_list.append(d)
                    sum[queryrun]['total_failed'] = sum[queryrun]['total_failed'] + 1
                    failed_queries_per_run[queryrun].append(d) 

                sum[queryrun]['average_firethorn_duration'] = float(float(sum[queryrun]['total_firethorn_querytime'])/int(sum[queryrun]['total_queries_run']))
                sum[queryrun]['average_sql_duration'] =  float(float(sum[queryrun]['total_sql_querytime'])/int(sum[queryrun]['total_queries_run']))
        except Exception as e:
            print e
	print(1)
	"""
	try:
            j = json.dumps(objects_list)
            objects_file = 'tmp/sql2json-all.js'
            f = open(objects_file,'w')
            print >> f, j
            f.close()
        except Exception as e:
	    print e
	"""
        j2 = json.dumps(failed_list)
        failed_file = 'tmp/sql2json-failed.js'
        f2 = open(failed_file,'w')
        print >> f2, j2
        f2.close()
        summary.append(sum) 
        j3 = json.dumps(summary)
        summary_list = 'tmp/sql2json-summary.js'
        f3 = open(summary_list,'w')
        print >> f3, j3
        f3.close()

        for i in failed_queries_per_run:
            j4 = json.dumps(failed_queries_per_run[i])
            failed_file = 'tmp/' + i + '.js'
            f4 = open(failed_file,'w')
            print >> f4, j4
            f4.close()

	print ("Done")             
        conn.close()
                  
if __name__ == "__main__":
    sql2Json = Sql2Json(config.reporting_dbserver, config.reporting_dbserver_username, config.reporting_dbserver_password, config.reporting_dbserver_port, "MySQL")              
    sql2Json.generateJson(config.reporting_database, "queries")             
 
