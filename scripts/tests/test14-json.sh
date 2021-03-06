#!/bin/bash -eu
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
#
#  Copyright (C) 2013 Royal Observatory, University of Edinburgh, UK
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

jsonfile=$1
echo "*** Initialising test1042 script [test14.sh] ***"

source ${HOME:?}/chain.properties

echo "*** Creating pyrothorn properties file [test14.sh] ***"


pyroproperties=$(mktemp)
cat > "${pyroproperties:?}" << EOF
import os

#------------------------- General Configurations -----------------------#

### Unit test specific configuration ###
use_preset_params = False # Use the preset firethorn resource parameters at the end of this config file
use_cached_firethorn_env = False #Use cached firethorn environment, stored in (testing/conf/pyrothorn-stored.js)
firethorn_version =  "${version:?}" 
include_neighbour_import = False # Choose whether to import all neighbour tables for a catalogue or not
test_is_continuation = False # Test is continued from prev run or not (If true, duplicate queries that have been run previously will not be run)

### Directory and URL Information ###
firethorn_host = "${firelink:?}" 
firethorn_port = "8080" 
full_firethorn_host = firethorn_host if firethorn_port=='' else firethorn_host + ':' + firethorn_port
base_location = os.getcwd()

### Email ###
test_email = "test@test.roe.ac.uk" 

### Queries ###
sample_query="Select top 10 * from Filter" 
sample_query_expected_rows=10
limit_query = None
sql_rowlimit = ${defaultrows:?}
sql_timeout = 1800
firethorn_timeout = 1800
query_mode = "AUTO" 

#------------------- Test Configurations ----------------------------------#

### SQL Database Configuration ###

test_dbserver= "${datalink:?}" 
test_dbserver_username = "${datauser:?}" 
test_dbserver_password = "${datapass:?}" 
test_dbserver_port = "${dataport:?}" 
test_database = "${testrundatabase:?}" 
neighbours_query = """ 
        SELECT DISTINCT
            ExternalSurvey.databaseName
        FROM
            RequiredNeighbours
        JOIN
            ExternalSurvey
        ON
            RequiredNeighbours.surveyID = ExternalSurvey.surveyID
        JOIN
            ExternalSurveyTable
        ON
            RequiredNeighbours.surveyID = ExternalSurveyTable.surveyID
        AND
            RequiredNeighbours.extTableID = ExternalSurveyTable.extTableID
        WHERE 
            ExternalSurvey.databaseName!='NONE'
        ORDER BY
            ExternalSurvey.databaseName
            """ 

### Reporting Database Configuration ###

reporting_dbserver= "${pyrosqllink:?}" 
reporting_dbserver_username = "root" 
reporting_dbserver_password = "" 
reporting_dbserver_port = "${pyrosqlport:?}" 
reporting_database = "pyrothorn_testing" 

### Logged Queries Configuration ###

stored_queries_dbserver= "${storedquerieslink:?}" 
stored_queries_dbserver_username = "${storedqueriesuser:?}" 
stored_queries_dbserver_password = "${storedqueriespass:?}" 
stored_queries_dbserver_port = "${storedqueriesport:?}" 
stored_queries_database = "${storedqueriesdata:?}" 
stored_queries_query = "select * from webqueries where dbname like 'ATLAS%' and query not like '%mi.arcfile%'" 
logged_queries_txt_file = "/queries.txt" 
logged_queries_json_file = "/queries.json"
 
### Firethorn Live test Configuration ###

adql_copy_depth = "FULL" 
resourcename = '${testrundatabase:?} JDBC conection' 
resourceuri = "jdbc:jtds:sqlserver://${datalink:?}/${testrundatabase:?}" 
adqlspacename = '${testrundatabase:?} Workspace'
catalogname = '*'
driver = '${datadriver:?}'
ogsadainame = '${testrun_ogsadai_resource:?}'
jdbccatalogname = '${testrundatabase:?}'
jdbcschemaname = 'dbo'
jdbc_resource_user = '${datauser:?}'
jdbc_resource_pass = '${datapass:?}'
metadocfile = "testing/metadocs/${testrundatabase:?}_TablesSchema.xml" 
metadocdirectory = "testing/metadocs/" 
stored_env_config = 'conf/pyrothorn-stored.js'

### Firethorn Predefined test Configuration ###

jdbcspace = "" 
adqlspace = "" 
adqlschema = "" 
query_schema = "" 
schema_name = "${testrundatabase:?}" 
schema_alias = "${testrundatabase:?}" 

EOF

testbase="$(pwd)/tests"
testdata="$(pwd)/tests/test-001"

chmod a+r "${testbase:?}/test14-nohup.sh" 
chcon -t svirt_sandbox_file_t "${testbase:?}/test14-nohup.sh" 

chmod a+r "${pyroproperties:?}" 
chcon -t svirt_sandbox_file_t "${pyroproperties:?}" 

mkdir -p /var/logs/${pyroname:?}

chmod a+r "${testdata:?}/metadoc.xml" 
chmod a+r "${jsonfile:?}" 
chcon -t svirt_sandbox_file_t "${testdata:?}/metadoc.xml" 
chcon -t svirt_sandbox_file_t "${jsonfile:?}" 

echo "*** Run pyrothorn  [test14-nohup.sh] ***"

docker run -i -t \
    --name ${pyroname:?} \
    --detach \
    --memory 512M \
    --volume "${pyroproperties:?}:/home/pyrothorn/config.py" \
    --volume "${testbase:?}/test14-nohup.sh:/scripts/test14-nohup.sh" \
    --volume "${jsonfile:?}:/queries.json" \
    --volume "${pyrologs}:/home/pyrothorn/logs" \
    --link "${firename:?}:${firelink:?}" \
    --link "${pyrosqlname:?}:${pyrosqllink:?}" \
    --link "${storedqueriesname:?}:${storedquerieslink:?}" \
    --link "${ogsaname:?}:${ogsalink:?}" \
    --link "${dataname:?}:${datalink:?}" \
    --link "${username:?}:${userlink:?}" \
       firethorn/pyrothorn:${version:?} bash -c  '/scripts/test14-nohup.sh'



