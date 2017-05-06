from urlparse import urlparse
from threading import Thread
import httplib, sys
import os
import pyodbc
from Queue import Queue
configdir = '../'
testdir = os.path.dirname(__file__)
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(testdir, configdir)))
from pyrothorn.pyroquery import firethornEngine
from pyrothorn.pyroquery import queryEngine
from pyrothorn.pyroquery.firethorn_config import web_services_sys_info
from pyrothorn.pyroquery.firethorn_config import tap_base
from pyrothorn.mssql import sqlEngine
from pyrothorn.pyroquery import voQuery
from random import randint

concurrent = 10
url = "http://astoalith.metagrid.xyz/firethorn/tap/osa"
querypath = '/home/pyrothorn/testing/query_logs/concurrent.txt'

def doWork():
    while True:
        query = q.get()
        print "Starting query: " + query 
        maxrec=randint(0,10)
        tap_row_length = runQuery(query,maxrec)
        if (tap_row_length==maxrec):
           print "Success"
        else:
           print "Fail"
        q.task_done()

def runQuery(query, maxrec):
    try:
	voqry = voQuery.VOQuery(endpointURL=url, query=query,  maxrec=maxrec)
        voqry.run()
	tap_row_length = voqry.get_votable_rowcount()
        return tap_row_length
    except Exception as e:
        return e

q = Queue(concurrent * 2)

for i in range(concurrent):
    t = Thread(target=doWork)
    t.daemon = True
    t.start()
try:
    for query in open(querypath):
        q.put(query.strip())
    q.join()
except KeyboardInterrupt:
    sys.exit(1)

