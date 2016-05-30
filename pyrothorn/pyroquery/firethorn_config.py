'''
Created on May 3, 2013

@author: stelios
'''
try:
    from config import *
except Exception as e:
    full_firethorn_host = "peter:8080"
    sql_rowlimit=100000
    sql_timeout = 1000
    firethorn_timeout = 6000000

web_services_url = "http://" + full_firethorn_host + "/firethorn"
web_services_sys_info = web_services_url + "/system/info"

### Query Runtime and Polling Configurations ###
MAX_FILE_SIZE = 248576000 
delay = 3
MIN_ELAPSED_TIME_BEFORE_REDUCE = 40
MAX_ELAPSED_TIME = 18000
MAX_DELAY = 15
INITIAL_DELAY = 2

#firethorn.limits.rows.default=1000,0000
firethorn_limits_rows_default=sql_rowlimit
firethorn_limits_cells_default=0
firethorn_limits_time_default=0

#firethorn.limits.rows.absolute=1000000
firethorn_limits_rows_absolute=sql_rowlimit
firethorn_limits_cells_absolute=0
firethorn_limits_time_absolute=60000000


firethorn_limits_time = 6000000

### URL, Type and Parameter associations and Information
get_jdbc_resources_url = "/firethorn/jdbc/resource/select"
get_adql_resources_url = "/firethorn/adql/resource/select"

get_param = 'id'

workspace_import_schema_name = "adql.resource.schema.import.name"
workspace_import_schema_base = "adql.resource.schema.import.base"
workspace_import_uri = "/schemas/import"

schema_import_schema_name = "adql.schema.table.import.name"
schema_import_schema_base = "adql.schema.table.import.base"
schema_import_uri = "/tables/import"

query_create_uri = "/queries/create"
query_update_uri = "/queries/update"
query_name_param = "adql.schema.query.create.name"
query_limit_rows_param = "adql.query.update.limit.rows"
query_limit_time_param = "adql.query.update.limit.time"

query_mode_param = "adql.schema.query.create.mode"

query_param = "adql.schema.query.create.query"
query_status_update = "adql.query.update.status"

schema_create_uri = '/schemas/create'
table_create_uri = '/tables/create'

table_import_uri = '/tables/import'

workspace_creator = web_services_url + "/adql/resource/create"
jdbc_creator = web_services_url + "/jdbc/resource/create"


resource_create_name_params = {
                               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : 'jdbc.resource.create.name', 
                               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : 'adql.resource.create.name',
                               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : 'adql.resource.create.name',
                               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-schema-1.0.json' : 'adql.resource.schema.create.name'
                               }


resource_create_url_params = {
                              'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : 'jdbc.resource.create.url',
                              'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : 'adql.resource.create.url',
                              'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : 'adql.resource.create.url'

                              }


resource_create_username_params = {
                                   'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : 'jdbc.resource.create.user',
                                   'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : 'adql.resource.create.user',
                                   'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : 'adql.resource.create.user'
                                   }


resource_create_password_params = {
                                   'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : 'jdbc.resource.create.pass',
                                   'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : 'adql.resource.create.pass',
                                   'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : 'adql.resource.create.pass'
                                   }


create_urls = {
               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : web_services_url + '/firethorn/jdbc/resource/create', 
               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : web_services_url + '/firethorn/adql/resource/create',
               'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : web_services_url + '/firethorn/adql/resource/create'
               }


get_urls = {
            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : web_services_url + '/firethorn/adql/resource/',
            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : web_services_url + '/firethorn/adql/resource/',
            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : web_services_url + '/firethorn/jdbc/resource/'
            }


db_select_by_name_urls = {
                          'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' : web_services_url + '/firethorn/adql/resource/select?',
                          'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' : web_services_url + '/firethorn/adql/resource/select?',
                          'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' : web_services_url + '/firethorn/jdbc/resource/select?'
                          }


db_select_with_text_urls = {
                            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json' :  web_services_url + '/firethorn/adql/resource/search?',
                            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json' :  web_services_url + '/firethorn/adql/resource/search?',
                            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json' :  web_services_url + ' /firethorn/jdbc/resource/search?'
                            }

type_select_uris = {'schemas' : '/schemas/select',
                    'tables' : '/tables/select',
                    'columns' : '/columns/select',
                    'workspaces' :'firethorn/adql/resources/select'
                    }                   
                       
resource_uris = {
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json': '/schemas/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-catalog-1.0.json': '/schemas/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-schema-1.0.json': '/tables/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-table-1.0.json': '/columns/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json': '/schemas/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json': '/schemas/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-catalog-1.0.json': '/schemas/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-schema-1.0.json': '/tables/select',
                 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-table-1.0.json': '/columns/select',
                 }


type_update_params = {
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json': 'jdbc.resource.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-catalog-1.0.json': 'jdbc.catalog.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-schema-1.0.json': 'jdbc.schema.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-table-1.0.json': 'jdbc.table.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-column-1.0.json': 'jdbc.column.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json': 'adql.resource.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json': 'adql.resource.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-catalog-1.0.json': 'adql.catalog.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-schema-1.0.json': 'adql.schema.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-table-1.0.json': 'adql.table.update.name',
                    'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-column-1.0.json': 'adql.column.update.name'
                    }


db_select_with_text_params = {
                              'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json': 'jdbc.resource.search.text',
                              'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json': 'adql.resource.search.text',
                              'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json': 'adql.resource.search.text'
                              }


db_select_by_name_params = {
                            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json': 'jdbc.resource.select.name',
                            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json': 'adql.resource.select.name',
                            'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json': 'adql.resource.select.name'
                            }
schema_select_by_name_param = "adql.resource.schema.select.name"
table_select_by_name_param = "adql.schema.table.select.name"

types = {
         'service' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json', 
         'Service' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-service-1.0.json',
         'JDBC connection' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json',
         'resource' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-resource-1.0.json',
         'catalog' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-catalog-1.0.json', 
         'jdbc_catalog' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-catalog-1.0.json', 
         'adql_catalog' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-catalog-1.0.json', 
         'jdbc_table' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-table-1.0.json',
         'adql_table' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-table-1.0.json',
         'jdbc_schema' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-schema-1.0.json',
         'adql_schema' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-schema-1.0.json',
         'jdbc_column' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/jdbc-column-1.0.json',
         'adql_column' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-column-1.0.json',
         'Workspace' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json',
         'workspace' : 'http://data.metagrid.co.uk/wfau/firethorn/types/entity/adql-resource-1.0.json'

        }


