'''
Created on Jul 22, 2013

@author: stelios
'''

import urllib2
import json
import pyrothorn
import logging
import urllib
import urllib2
from datetime import datetime
import firethorn_config as config

class FirethornEngine(object):
    '''
    FirethornEngine
    
    Class that provides the infrastructure to use the Firethorn project
    '''

    def __init__(self, jdbcspace="", adqlspace="", adqlschema="", query_schema="", schema_name="", schema_alias="", driver="" , **kwargs):
        '''
        Constructor
        :param jdbcspace:
        :param adqlspace:
        :param adqlschema:
        :param query_schema:
        :param schema_name:
        :param schema_alias:
        '''
       
        self.jdbcspace = ""
        self.adqlspace =  ""
        self.adqlschema = ""
        self.query_schema = ""
        self.schema_name = ""
        self.schema_alias = ""
        self.jdbcspace = jdbcspace
        self.adqlspace =  adqlspace
        self.adqlschema = adqlschema
        self.query_schema = query_schema
        self.schema_name = schema_name
        self.schema_alias = schema_alias
        self.driver = driver
        
    def setUpFirethornEnvironment(self, resourcename ,resourceuri, catalogname, ogsadainame, adqlspacename, jdbccatalogname, jdbcschemaname, metadocfile, jdbc_resource_user="", jdbc_resource_pass=""):
        '''
        Initialise the Firethorn environment
        Import metadata, setup initial workspace, import schemas, tables
        
        :param resourcename:
        :param resourceuri:
        :param catalogname:
        :param ogsadainame:
        :param adqlspacename:
        :param jdbccatalogname:
        :param jdbcschemaname:
        :param metadocfile:
        '''
        try:

	    self.initialise_metadata_import(resourcename ,resourceuri, catalogname, ogsadainame, adqlspacename, jdbccatalogname, jdbcschemaname, metadocfile, jdbc_resource_user, jdbc_resource_pass)
            self.schema_name = self.getAttribute(self.adqlschema, "fullname" )
            self.schema_alias = self.getAttribute(self.adqlschema, "name" )
            self.query_schema = self.create_initial_workspace(self.schema_name, self.schema_alias, self.adqlschema)
        except Exception as e:
            logging.exception("Error during pyrothorn initialization")

                    
    def initialise_metadata_import(self, resourcename ,resourceuri, catalogname, ogsadainame, adqlspacename, jdbccatalogname, jdbcschemaname, metadocfile, jdbc_resource_user="", jdbc_resource_pass="" ):
        '''
        Import metadata, fetch Schema from file provided
        
        :param resourcename:
        :param resourceuri:
        :param catalogname:
        :param ogsadainame:
        :param adqlspacename:
        :param jdbccatalogname:
        :param jdbcschemaname:
        :param metadocfile:
	:param jdbc_resource_user
	:param jdbc_resource_pass
        '''
        self.jdbcspace = self.create_jdbc_space(resourcename ,resourceuri, catalogname, ogsadainame, jdbc_resource_user, jdbc_resource_pass)
        if (self.adqlspace=="" or self.adqlspace==None):
	    self.adqlspace = self.create_adql_space(adqlspacename)
        self.adqlschema = self.import_jdbc_metadoc(self.adqlspace, self.jdbcspace, jdbccatalogname, jdbcschemaname, metadocfile)
         
         
    def create_jdbc_space(self, resourcename ,resourceuri, catalogname, ogsadainame, jdbc_resource_user="", jdbc_resource_pass=""):
        '''
        Create a JDBC resource 
        :param resourcename:
        :param resourceuri:
        :param catalogname:
        :param ogsadainame:
        '''
        
        jdbcspace=""
        try:
         
	    if jdbc_resource_user!="" and jdbc_resource_pass!="":
                data = urllib.urlencode({config.resource_create_name_params['http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json'] : resourcename,
 				     "urn:jdbc.copy.depth" : config.adql_copy_depth,
                                     "jdbc.resource.create.url" : resourceuri,
                                     "jdbc.resource.create.catalog" : catalogname,
                                     "jdbc.resource.create.ogsadai" : ogsadainame,
                                     "jdbc.resource.create.name" : ogsadainame,
                                     "jdbc.resource.create.driver" : self.driver,
                                     "jdbc.resource.create.user" : jdbc_resource_user,
                                     "jdbc.resource.create.pass" : jdbc_resource_pass
                                    })
				    

	    else :
                data = urllib.urlencode({config.resource_create_name_params['http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json'] : resourcename ,
                                     "urn:jdbc.copy.depth" : config.adql_copy_depth,
                                     "jdbc.resource.create.url" : resourceuri,
                                     "jdbc.resource.create.catalog" : catalogname,
				     "jdbc.resource.create.driver" : self.driver,
                                     "jdbc.resource.create.ogsadai" : ogsadainame,
                                    })

	

            req = urllib2.Request( config.jdbc_creator, data, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email , "firethorn.auth.community" : "public (unknown)"})
            response = urllib2.urlopen(req)
            jdbcspace = json.loads(response.read())["ident"]
            response.close()
        except Exception as e:
            logging.exception("Error creating jdbc space")
        return jdbcspace    
    

    def import_jdbc_metadoc(self, adqlspace="", jdbcspace="", jdbccatalogname='', jdbcschemaname='dbo',metadocfile=""):
        '''
         Import a JDBC metadoc
        :param adqlspace:
        :param jdbcspace:
        :param jdbccatalogname:
        :param jdbcschemaname:
        :param metadocfile:
        '''
      
        jdbcschemaident = ""
        adqlschema=""
        import pycurl
        import cStringIO
        
        buf = cStringIO.StringIO()
        try:
            data = urllib.urlencode({"jdbc.resource.schema.select.catalog" : jdbccatalogname,
                                     "jdbc.resource.schema.select.schema" : jdbcschemaname})
            req = urllib2.Request( jdbcspace + "/schemas/select", data, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email , "firethorn.auth.community" : "public (unknown)"})
            response = urllib2.urlopen(req)
            jdbcschemaident = json.loads(response.read())["ident"]
            response.close()
        except Exception as e:
            logging.exception("Error creating importing jdbc metadoc:  " + jdbcschemaident)
    
        try:
           
            c = pycurl.Curl()   
            
            url = adqlspace + "/metadoc/import"        
            values = [  
                      ("urn:schema.metadoc.base", str(jdbcschemaident)),
                      ("urn:schema.metadoc.file", (c.FORM_FILE, metadocfile))]
                       
            c.setopt(c.URL, str(url))
            c.setopt(c.HTTPPOST, values)
            c.setopt(c.WRITEFUNCTION, buf.write)
            c.setopt(pycurl.HTTPHEADER, [ "firethorn.auth.identity",config.test_email,
                                          "firethorn.auth.community","public (unknown)"
                                          ])
            c.perform()
            c.close()
	    adqlschema = json.loads(buf.getvalue())[0]["ident"]
            buf.close() 
            
        except Exception as e:
            logging.exception("Error creating importing jdbc metadoc" )
     
        return adqlschema
    
    
    
    def create_adql_space(self, adqlspacename=None):
        '''
        Create an ADQL resource

        :param adqlspacename:
        '''
     
        adqlspace = ""
        try:
            ### Create workspace
            if adqlspacename==None:
                t = datetime.now()
                adqlspacename = 'workspace-' + t.strftime("%y%m%d_%H%M%S") 
            data = urllib.urlencode({config.resource_create_name_params['http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json'] : adqlspacename,
                                     "urn:adql.copy.depth": config.adql_copy_depth})
            req = urllib2.Request( config.workspace_creator, data, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email , "firethorn.auth.community" : "public (unknown)"})
            response = urllib2.urlopen(req)
            adqlspace = json.loads(response.read())["ident"]
            response.close()
        except Exception as e:
            logging.exception("Error creating ADQL space")
        return adqlspace
                         
                         
    def create_query_schema(self, resource=""):
        '''
        Create a query schema
 
        :param resource:
        '''
        query_schema = ""
        try:    
            ### Create Query Schema 
            data = urllib.urlencode({config.resource_create_name_params['http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-schema-1.0.json'] : "query_schema"})
            req = urllib2.Request( resource +  config.schema_create_uri, data, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email, "firethorn.auth.community" : "public (unknown)"})
            response = urllib2.urlopen(req) 
            query_schema = json.loads(response.read())["ident"]
            response.close()
        except Exception as e:
            logging.exception("Error creating query schema")
        return query_schema
    
        
    def create_initial_workspace(self, initial_catalogue_fullname, initial_catalogue_alias, initial_catalogue_ident):
        '''
        Create the inital workspace given a name, alias and catalogue identifier
        
        :param initial_catalogue_fullname:
        :param initial_catalogue_alias:
        :param initial_catalogue_ident:
        '''
      
        query_schema =""
        importname = ""
        t = datetime.now()
	workspace = self.create_adql_space()
        self.adqlspace = workspace
	query_schema = self.create_query_schema(workspace)
        
        name = initial_catalogue_fullname
        alias = initial_catalogue_alias
        ident = initial_catalogue_ident
        data = None
        try:   
            if alias!="":
                importname = alias
            else :
                importname = name

            if importname!="":
                data = urllib.urlencode({'urn:adql.copy.depth' : config.adql_copy_depth, config.workspace_import_schema_base : ident, config.workspace_import_schema_name : importname})
	        req = urllib2.Request( workspace + config.workspace_import_uri, data, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email, "firethorn.auth.community" : "public (unknown)"}) 
                response = urllib2.urlopen(req)
        except Exception as e:
            logging.exception("Error importing catalogue")
       
        return query_schema
    
    
    def printClassVars(self):
        '''
        Print out the class (Firethorn environment) variables
        '''
        logging.info("jdbcspace: " + self.jdbcspace)
        logging.info("adqlspace: " + str(self.adqlspace))
        logging.info("adqlschema: " + str(self.adqlschema))
        logging.info("query_schema: " + str(self.query_schema))
        logging.info("schema_name: " + str(self.schema_name))
        logging.info("schema_alias: " + str(self.schema_alias))     
    
    
    def getAttribute(self, ident, attr):
        '''
        Get an attribute of a JSON HTTP resource
        
        :param ident:
        :param attr:
        '''
    
        attr_val = []
        try :
            req_exc = urllib2.Request( ident, headers={"Accept" : "application/json", "firethorn.auth.identity" : config.test_email, "firethorn.auth.community" :"public (unknown)"})
            response_exc = urllib2.urlopen(req_exc) 
            response_exc_json = response_exc.read()
            attr_val = json.loads(response_exc_json)[attr]
            response_exc.close()
        except Exception as e:
            logging.exception(e)
        return attr_val
        
    
