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
    import config
    from pyrothorn.pyroquery import firethornEngine
    from pyrothorn.pyroquery import queryEngine
    from pyrothorn.pyroquery.firethorn_config import web_services_sys_info
    from pyrothorn.pyroquery.firethorn_config import tap_base
    from pyrothorn.mssql import sqlEngine
    import uuid
    from time import gmtime,  strftime
    import datetime
    import base64
    import collections
    import hashlib
    from pyrothorn.pyroquery import voQuery
    #sys.stdout = open('logs/logfile.txt', 'w')
except Exception as e:
    logging.info(e)

def get_a_uuid():
    '''
    Generate uuid
    '''
    r_uuid = base64.urlsafe_b64encode(uuid.uuid4().bytes)
    return r_uuid.replace('=', '')


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
        self.total_failed = 0
        self.total_queries = 0
	self.total_unique_queries = 0
        self.verificationErrors = []
        self.sample_query=config.sample_query
        self.sample_query_expected_rows=config.sample_query_expected_rows
        self.setUpLogging()
   
   
    def test_logged_queries(self):
        '''
        Test the logged sql queries against firethorn
        '''
        
        try:
            firethorn_version = ""
            java_version = ""
            sys_platform = ""
            sys_timestamp = ""
            firethorn_changeset = ""
            firethorn_version = ""
            name = ""
            defaultrows = 1000000
            absoluterows = 10000000
            sqlEng = sqlEngine.SQLEngine(config.test_dbserver, config.test_dbserver_username, config.test_dbserver_password, config.test_dbserver_port)
            
            jsondata=[]

            with open(config.jsonconfig ) as f:
                data = json.load(f)
                for key, value in data.iteritems():
                    if key.lower()=="jdbcresource":
                        jdbcresource=value
                    elif key.lower()=="adqlresources":
                        resources = value
                    elif key.lower()=="endpointurl":
                        endpointurl = value
                    elif key.lower()=="defaultrows":
                        defaultrows = value
                    elif key.lower()=="absoluterows":
                        absoluterows = value
                    elif key.lower()=="name":
                        name = value
                    elif key.lower()=="metadata":
                        metadata=value
                    if key.lower()=="userdata":
                        userdata=value


                fEng = firethornEngine.FirethornEngine( schema_name=jdbcresource.get("database",''), schema_alias=jdbcresource.get("database",''),driver=jdbcresource.get("driver",''))

                count=0
                for resource in resources:
                    name = resource["name"]
                    metadoc = resource["metadoc"]
                    if (count==0):
                        fEng.setUpFirethornEnvironment(jdbcresource.get("database",''), jdbcresource.get("jdbcuri",''), "*", name, jdbcresource.get("database",''), jdbcresource.get("database",''), "dbo", metadoc, jdbcresource.get("user",''), jdbcresource.get("pass",''))
                        fEng.printClassVars()
                    else:
                        fEng.import_jdbc_metadoc(fEng.adqlspace, fEng.jdbcspace, name, 'dbo', metadoc)

                    count = count + 1
               
                firethorn_tap_service=tap_base + os.path.basename(fEng.adqlspace)
             
                # Generate TAP_SCHEMA
                data = urllib.urlencode({"url" : metadata.get("jdbcuri",'') + '/' + metadata.get("database",""),"user" : metadata.get("user",''),"pass" : metadata.get("pass",''),"driver" : metadata.get("driver",''),"catalog" : metadata.get("database",''),"user" : metadata.get("user",'') })
                req = urllib2.Request( firethorn_tap_service + "/generateTapSchema", data, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email , "firethorn.auth.community" : "public (unknown)"})
                response = urllib2.urlopen(req)
                response.close()


                # Write TAP service URL to file 
		file = open("/tap_service", "w")
		file.write(firethorn_tap_service) 
		file.close()

                logging.info("TAP Service available at: " + firethorn_tap_service)
        except Exception as e:
            logging.info(e)
   
                
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

