try:
    from urlparse import urlparse
    from threading import Thread
    import httplib, sys
    import os
    import pyodbc
    from Queue import Queue
    configdir = '../'
    testdir = os.path.dirname(__file__)
    sys.path.insert(0, os.path.dirname(__file__))
    from pyrothorn.pyroquery import firethornEngine
    from pyrothorn.pyroquery import queryEngine
    sys.path.insert(0, os.path.abspath(os.path.join(testdir, configdir)))
    from pyrothorn.pyroquery.firethorn_config import web_services_sys_info
    from pyrothorn.pyroquery import firethornEngine
    from pyrothorn.pyroquery import queryEngine
    from random import randint
    from config import *
    import logging
except Exception as e:
    logging.info(e)

concurrent = 10
url = "http://astoalith.metagrid.xyz/firethorn/tap/osa"
querypath = '/home/pyrothorn/testing/query_logs/concurrent.txt'
query_schema = ''

def doWork():
    while True:
        query = q.get()
        print "Starting query: " + query 
        maxrec=randint(0,10)
        row_length = runQuery(query,maxrec)
        print row_length 
        if (row_length==maxrec):
           print "Success"
        else:
           print "Fail"
        q.task_done()

def runQuery(query, maxrec):
    try:
        qEng = queryEngine.QueryEngine()
        firethorn_row_length, firethorn_error_message = qEng.run_query(query, "", query_schema)
        return firethorn_row_length
    except Exception as e:
        print e
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

