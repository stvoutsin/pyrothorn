try:
    import sys, os
    import errno
    import signal
    configdir = '../'
    testdir = os.path.dirname(__file__)
    sys.path.insert(0, os.path.dirname(__file__))
    sys.path.insert(0, os.path.abspath(os.path.join(testdir, configdir)))
    import os.path
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.common.keys import Keys
    from selenium.webdriver.support.ui import Select
    from selenium.common.exceptions import NoSuchElementException
    import unittest, time, re
    from selenium.webdriver.common.action_chains import ActionChains
    from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
    from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0
    import logging
    import urllib2
    import json
    import urllib
    from pyrothorn.pyroquery import firethornEngine
    from pyrothorn.pyroquery import queryEngine
    from pyrothorn.pyroquery.firethorn_config import web_services_sys_info
    from pyrothorn.mssql import sqlEngine
    import config
    import uuid
    from time import gmtime,  strftime
    import datetime
    import base64
    import collections
    import hashlib
    import json
    from pprint import pprint

    # get a UUID - URL safe, Base64
    def get_a_uuid():
        '''
        Generate uuid
        '''
        r_uuid = base64.urlsafe_b64encode(uuid.uuid4().bytes)
        return r_uuid.replace('=', '')
except Exception as e:
    logging.info(e)

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

class test_firethorn(unittest.TestCase):
            
               
    def setUp(self):
        self.use_preset_params = config.use_preset_params
        self.use_cached_firethorn_env = config.use_cached_firethorn_env
        self.total_failed = 0
        self.total_queries = 0
	self.total_unique_queries = 0
        self.include_neighbours = config.include_neighbour_import
        self.verificationErrors = []
        self.sample_query=config.sample_query
        self.sample_query_expected_rows=config.sample_query_expected_rows
        self.setUpLogging()
   
   
    def test_logged_queries(self):
        '''
        Test the logged sql queries against firethorn
        '''
        
        try:
            queryrunID = ""
	    logged_queries=[]
            logged_query_sqlEng = sqlEngine.SQLEngine(config.stored_queries_dbserver, config.stored_queries_dbserver_username, config.stored_queries_dbserver_password, config.stored_queries_dbserver_port)
            sqlEng = sqlEngine.SQLEngine(config.test_dbserver, config.test_dbserver_username, config.test_dbserver_password, config.test_dbserver_port)
            reporting_sqlEng = sqlEngine.SQLEngine(config.reporting_dbserver, config.reporting_dbserver_username, config.reporting_dbserver_password, config.reporting_dbserver_port, "MySQL")

            
            log_sql_query = config.stored_queries_query
            logging.info("Setting up Firethorn Environment..")
            fEng = firethornEngine.FirethornEngine( schema_name=config.schema_name, schema_alias=config.schema_alias,driver = config.driver )
            queryrunID = get_a_uuid() 
            fEng.setUpFirethornEnvironment( config.resourcename , config.resourceuri, config.catalogname, config.ogsadainame, config.adqlspacename, config.jdbccatalogname, config.jdbcschemaname, config.metadocfile, config.jdbc_resource_user, config.jdbc_resource_pass)

	    fEng.printClassVars()
            

	    try:
                java_version = fEng.getAttribute(web_services_sys_info, "java")["version"]
                sys_platform = fEng.getAttribute(web_services_sys_info, "system")["platform"]
                sys_timestamp = fEng.getAttribute(web_services_sys_info, "system")["time"]
                firethorn_changeset = fEng.getAttribute(web_services_sys_info, "build")["changeset"]
                firethorn_version = fEng.getAttribute(web_services_sys_info, "build")["version"]
            except Exception as e:
		java_version = ""
                sys_platform = ""
                sys_timestamp = ""
                firethorn_changeset = ""
                firethorn_version = ""
	        logging.info(e)
            logging.info("")
       
	    logging.info("") 		    
	    continue_from_here_flag = False
            self_total_unique_queries = 0
            self.total_queries = 0
            self.total_failed = 0  
            jsondata=[]

            with open(config.logged_queries_json_file ) as f:
                data = json.load(f)
                for key, value in data.iteritems():
                    if key.lower()=="queries":
                        queries=value
                    elif key.lower()=="resources":
                        resources = value	

                for resource in resources:
                    resourcetype = resource["type"]
                    url = resource["url"]
                    metadoc = resource["metadoc"]
                    alias = resource["alias"]
                    name = resource["name"]
                    schema = resource["schema"]
 
                    if resourcetype.lower()=="ivoa":
                        fEng.import_ivoa_schema(alias, url, metadoc, name, schema, fEng.adqlspace)

                for line in queries:
                    query = line["query"]
                    sql_row_length = line["rows"]
                    qEng = queryEngine.QueryEngine()
                    query = str(query.strip())
                    querymd5 = self.md5String(query)
		    query_duplicates_found = 0
		    queryid = None
                    query_count = 0
                    firethorn_error_message = ""
                    sql_error_message =  ""
                    logging.info("Query : " +  query)
                    self.total_queries = self.total_queries + 1

                    if (True):
                        continue_from_here_flag = True
                        sql_duration = 0
                        firethorn_duration = 0
                        test_passed = -1
                        test_skipped = False
                        sql_start_time = time.time()
                        query_timestamp = datetime.datetime.fromtimestamp(sql_start_time).strftime('%Y-%m-%d %H:%M:%S')
                        firethorn_row_length = -1
                        sql_error_message = ""
                        firethorn_error_message = ""
                        self.total_unique_queries = self.total_unique_queries+1
                        
                        try:                    
                    	    start_time = time.time()
			    logging.info("Started Firethorn job :::" +  strftime("%Y-%m-%d %H:%M:%S", gmtime()))
			    with Timeout(config.firethorn_timeout):
			        firethorn_row_length, firethorn_error_message = qEng.run_query(query, "", fEng.query_schema)
			    logging.info("Finished Firethorn job :::" +  strftime("%Y-%m-%d %H:%M:%S", gmtime()))
			    logging.info("Firethorn Query: " + str(firethorn_row_length) + " row(s) returned. ")
			    firethorn_duration = float(time.time() - start_time)


			    logging.info("")
                        
                        except Exception as e:
                           if (type(e).__name__=="Timeout"):
                               test_skipped = True
                               logging.info("Timeout reached while running firethorn query..")
                           else :
                               logging.info("Error caught while running firethorn query..")



                        test_passed = (sql_row_length == firethorn_row_length)
                        logging.info("---------------------- End Query Test ----------------------")
                        if test_passed:                    
			    logging.info("Query Successful !!")
		        else:
			    logging.info("Query Failed..")

                        if (not test_passed and (not test_skipped)):
			    self.total_failed = self.total_failed + 1

                        logging.info("")
                        logging.info("")
                        logging.info("")

                        params = (query, queryrunID, querymd5, 1,  query_timestamp, sql_row_length, firethorn_row_length, firethorn_duration, sql_duration, test_passed, firethorn_version, str(firethorn_error_message).encode('utf-8'), str(sql_error_message).encode('utf-8'), java_version, firethorn_changeset, sys_platform, sys_timestamp )
                        report_query = "INSERT INTO queries (query, queryrunID, query_hash, query_count, query_timestamp, direct_sql_rows, firethorn_sql_rows, firethorn_duration, sql_duration, test_passed, firethorn_version, firethorn_error_message, sql_error_message, java_version, firethorn_changeset, sys_platform, sys_timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" 
                        reporting_sqlEng.execute_insert(report_query, config.reporting_database, params=params)
                        #self.total_queries = self.total_queries + 1

                    else :
                        if (queryid!=None and query_count!=None and (continue_from_here_flag==True)):
                    	    logging.info("Query has been run already..Skipping & updating count")
			    update_query = "UPDATE queries SET query_count=" + str(query_count + 1) + " WHERE queryid=" + str(queryid)
			    update_results = reporting_sqlEng.execute_update(update_query, config.reporting_database)
			    #self.total_queries = self.total_queries + 1

                    logging.info("Total queries: "  + str(self.total_queries))
                    logging.info("Total unique queries: "  + str(self.total_unique_queries))
                    logging.info("Total failed: " + str(self.total_failed))

		logging.info("Success percentage: " +  str(round(100-(float(self.total_failed)/float(self.total_unique_queries))*100,2)) + "%")

        except Exception as e:
            logging.exception(e)
        # Test if total queries failed > 0            
        self.assertEqual(self.total_failed , 0, "Total queries failed: " + str(self.total_failed) + " (out of " + str(self.total_queries) +  ")" )
   
                
    def setUpLogging(self):
        '''
        set up logging procedure
        '''
        root = logging.getLogger()
        root.setLevel(logging.INFO)
        ch = logging.StreamHandler(sys.stdout)
        ch.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        root.addHandler(ch)
    
                    
    def tearDown(self):
        self.assertEqual([], self.verificationErrors)
        
        
    def md5String(self, str):
        m = hashlib.md5()
        m.update(str)
        return m.hexdigest()    
        
    
    def import_neighbours(self, sqlEng, fEng):
        '''
        
        :param sqlEng:
        :param fEng:
        '''
        neighbour_tables = sqlEng.execute_sql_query(config.neighbours_query, config.test_database)
        for i in neighbour_tables:
            logging.info("Importing " + i[0])
            fEng.import_jdbc_metadoc(fEng.adqlspace, fEng.jdbcspace, i[0], config.jdbcschemaname, config.metadocdirectory + "/" + i[0].upper() + "_TablesSchema.xml" )
      
    
    def store_environment_config(self, fEng, stored_config_file, queryrunID):
        '''
        
        :param fEng:
        :param stored_config_file:
        '''
        stored_config = collections.OrderedDict()
        stored_config['jdbcspace'] = fEng.jdbcspace
        stored_config['adqlspace'] = fEng.adqlspace
        stored_config['query_schema'] = fEng.query_schema
        stored_config['queryrunID'] = queryrunID
        j = json.dumps(stored_config)
        f = open(stored_config_file,'w')
        print >> f, j
        f.close()       

if __name__ == "__main__":
    unittest.main()

