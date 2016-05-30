import sys, os
configdir = '../'
testdir = os.path.dirname(__file__)
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(testdir, configdir)))
from pyrothorn.selenium import webdriver
from pyrothorn.selenium.webdriver.common.by import By
from pyrothorn.selenium.webdriver.common.keys import Keys
from pyrothorn.selenium.webdriver.support.ui import Select
from pyrothorn.selenium.common.exceptions import NoSuchElementException
import unittest, time, re
from pyrothorn.selenium.webdriver.common.action_chains import ActionChains
from pyrothorn.selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
from pyrothorn.selenium.webdriver.support import expected_conditions as EC # available since 2.26.0
import logging
import urllib2
import json
import pyrothorn
import urllib
from pyrothorn.pyroquery import firethornEngine
from pyrothorn.pyroquery import queryEngine
from pyrothorn.mssql import sqlEngine
import config


class test_firethorn(unittest.TestCase):
            
               
    def setUp(self):
        self.use_preset_params = False
        self.verificationErrors = []
        self.sample_query=config.sample_query
        self.sample_query_expected_rows=config.sample_query_expected_rows
        self.setUpLogging()
    
    def test_sample_firethorn_query(self):
        try:
            if (self.use_preset_params):
                fEng = pyrothorn.firethornEngine.FirethornEngine(config.jdbcspace, config.adqlspace, config.adqlschema, config.query_schema, config.schema_name, config.schema_alias)
                fEng.printClassVars()
            else:
                fEng = pyrothorn.firethornEngine.FirethornEngine()
                fEng.setUpFirethornEnvironment( config.resourcename , config.resourceuri, config.catalogname, config.ogsadainame, config.adqlspacename, config.jdbccatalogname, config.jdbcschemaname, config.metadocfile)
                fEng.printClassVars()
            qEng = queryEngine.QueryEngine()
        except Exception as e:
            logging.exception(e)
        row_length = qEng.run_query(self.sample_query, "", fEng.query_schema)
        
        self.assertEqual(row_length, self.sample_query_expected_rows)

      
    def setUpLogging(self):
        root = logging.getLogger()
        root.setLevel(logging.INFO)
        ch = logging.StreamHandler(sys.stdout)
        ch.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        root.addHandler(ch)
    
            
                    
    def tearDown(self):
        self.assertEqual([], self.verificationErrors)

if __name__ == "__main__":
    unittest.main()
