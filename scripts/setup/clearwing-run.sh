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


source "${HOME:?}/chain.properties"

clearwinglog=clearwing
clearwinglogs="/var/logs/${clearwinglog:?}"
setupdir="${HOME:?}/setup"
homedir="${HOME:?}"

chcon -t svirt_sandbox_file_t "${setupdir:?}/apache-clearwing-init.sh" 
chmod +x "${setupdir:?}/apache-clearwing-init.sh"


### Create config.py
properties=$(mktemp)
    cat > "${properties:?}" << EOF

import web
import os
import logging

### Mail Information
web.config.smtp_server = 'mail.roe.ac.uk'
from_email = "stv@roe.ac.uk"

### Survey Information
survey_short = 'OSA';
survey_full = 'OmegaCAM Science Archive (OSA)';

### Template renders
render = web.template.render('templates/')
gloss_render = web.template.render('templates/schema_browser/gloss/')
schema_browser_render = web.template.render('templates/schema_browser/')
main_page_render = web.template.render('templates/main_page/')
wfau_page_render = web.template.render('templates/wfau/')
monitoring_render = web.template.render('templates/monitoring/')

## Directory and URL Information
host = "${clearwing_host:?}"
port = "${clearwing_port:?}"
base_host = host if port=='' else host + ':' + port
sub_app_prefix='${clearwing_host_alias:?}'
base_location = os.getcwd()
userhomedir =  base_location
survey_sub_path = sub_app_prefix + "/" if sub_app_prefix!='' else ''#""
survey_prefix = '/' + sub_app_prefix if sub_app_prefix!='' else '' #""
cur_static_dir = base_location + '/static/static_vo_tool/'
vospace_dir = base_location + '/static/static_vospace'
base_url = 'http://' +  base_host + '/' + survey_sub_path 
publicly_visible_temp_dir = base_url + '/static/static_vo_tool/temp/'
host_temp_directory = base_location + '/static/static_vo_tool/temp/'
log_directory = base_location + '/log/'
firethorn_base = "http://${firelink:?}:8080/firethorn"
firethorn_ini = base_location  + '/firethorn.ini'
firethorn_tap_base = "${firethorn_tap_base:?}"

try:
    firethorn_base = dict(line.strip().split('=') for line in open(firethorn_ini ))['firethorn_base']
except:
    logging.exception("Error initializing firethorn base")

### Set to false when launching
web.config.debug = False 



### Configurations
live = True
debug_mode = False
no_users = True
offline=False
use_config = 'singletap'
mode_global = 'async'
request = 'doQuery'
result_format = 'votable'
lang = 'ADQL'
MAX_FILE_SIZE = 4048576000 #use : 104857600
MAX_ROW_SIZE = 5000000
MAX_CELL_SIZE = 20000000
delay = 3
use_cached_endpoints = 0
global_precision = 0.0000001
MIN_ELAPSED_TIME_BEFORE_REDUCE = 40
MAX_ELAPSED_TIME = 18000
MAX_DELAY = 15
INITIAL_DELAY = 1



### Survey, Servlet and CGI URLs

registry_url = 'http://registry.astrogrid.org/astrogrid-registry/main/xqueryresults.jsp'
tap_factory = "http://admire3.epcc.ed.ac.uk:8081/TAPFactory/create"
getImageURL = "http://seshat.roe.ac.uk:8080/osa/GetImage"
multiGetImageURL = "http://seshat.roe.ac.uk:8080/osa/MultiGetImage"
multiGetImageTempURL = 'http://seshat.roe.ac.uk/osa/tmp/MultiGetImage/'
crossIDURL = "http://seshat.roe.ac.uk:8080/osa/CrossID"
survey_cgi_bin = 'http://surveys.roe.ac.uk/wsa/cgi-bin/'
radialURL = "http://surveys.roe.ac.uk:8080/ssa/SSASQL"


## Database and TAP Information

SURVEY_TAP =  "${clearwing_tap_service:?}"
SURVEY_TAP_TITLE = "${clearwing_tap_service_title:?}"
SURVEY_DB =  "${survey_database:?}"
PRIVATE_SURVEY_DB = "${private_survey:?}"
PRIVATE_SURVEY_DB_VPHAS = "${private_survey_vphas:?}"
FULL_SURVEYDBS = ['', '']
FULL_SURVEYDBS_INC_SYNC = ['OSA_DailySync']
PRIVATE_FULL_SURVEYDBS = [""]
PRIVATE_SURVEYDBS_VPHAS = ['${private_survey_vphas:?}']

community = "${default_community:?}"
dbuser = "${survey_database_user:?}"
dbpasswd = "${survey_database_password:?}"
dbserver = "${survey_database_server:?}"
vphasdbuser = "${vphasdbuser:?}"
vphasdbpasswd = "${vphasdbpasswd:?}"
vphasdbserver = "${vphasdbserver:?}"


database_users = "${authentication_database:?}"
table_users = "${authentication_table:?}"
userdb_user = "${authentication_database_user:?}"
userdb_pw = "${authentication_database_password:?}"
dbqueries = "${query_store_database_server:?}"
dbnamequeries = "${query_store_database:?}"
dbtablequeries = "${query_store_table:?}"

database_imageList = SURVEY_DB

db_to_tap_map = {SURVEY_DB : SURVEY_TAP, 'ATLASv20131127' : 'http://djer-p:8083/atlas20131127-dsa/TAP/', 'ATLASDR2' : 'http://djer-p:8083/atlasDR2-dsa/tap', 'VPHASv20160112' : 'http://djer.roe.ac.uk:8083/vphas20160112-dsa/TAP/'}
taps_using_binary = ["http://dc.zah.uni-heidelberg.de"]
EOF


 ### Create odbcinst.ini

odbcinst=$(mktemp)
    cat > "${odbcinst:?}" << EOF
	[ODBC Drivers]
	TDS             = Installed

	[TDS]
	Description     = TDS driver (Sybase/MS SQL)
	Driver          = /usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
	Setup           = /usr/lib/x86_64-linux-gnu/odbc/libtdsS.so
	FileUsage       = 1

	[ODBC]
	Trace           = No
	TraceFile       = /tmp/sql.log
	ForceTrace      = No
	Pooling         = No

	[MySQL]
	Description = ODBC for MySQL
	Driver = /usr/lib/x86_64-linux-gnu/odbc/libmyodbc.so
	FileUsage = 1

EOF


### Create firethorn.ini

firethornini=$(mktemp)
    cat > "${firethornini:?}" << EOF
adqlspace=http://${firelink:?}:8080/firethorn/adql/resource/32669697
atlasschema=http://${firelink:?}:8080/firethorn/adql/schema/32702514
atlasprivate=http://${firelink:?}:8080/firethorn/adql/schema/32702514
vphasprivate=http://${firelink:?}:8080/firethorn/adql/schema/32702514
firethorn_base=http://${firelink:?}:8080/firethorn
EOF



### Create 000-default.conf file

apacheconf=$(mktemp)
    cat > "${apacheconf:?}" << EOF
<VirtualHost *:80>

   
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	#Include conf-available/serve-cgi-bin.conf

      
        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Order allow,deny
                Allow from all
        </Directory>

      ErrorLog /var/log/apache2/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog /var/log/apache2/access.log combined
        ServerSignature On
 
    #### VO Interface Setup ####
        WSGIScriptAlias /osa /var/www/html/atlas/app.py/

        Alias /osa/static     /var/www/html/atlas/static/
        AddType text/css .css
        AddType text/javascript .js
        AddType text/html .htm
        AddType image/gif .gif
        AddType image/jpeg .jpeg .jpg

        <Directory /var/www/html/atlas/static>
                # directives to effect the static directory
                Options +Indexes
        </Directory>


</VirtualHost>

EOF



chmod a+r "${properties:?}" 
chmod a+r "${odbcinst:?}" 
chmod a+r "${firethornini:?}" 
chmod a+r "${apacheconf:?}" 

chcon -t svirt_sandbox_file_t "${properties:?}" 
chcon -t svirt_sandbox_file_t "${odbcinst:?}" 
chcon -t svirt_sandbox_file_t "${firethornini:?}" 
chcon -t svirt_sandbox_file_t "${apacheconf:?}" 


docker run  \
    --detach \
    -p 80:80 \
    --memory 512M \
    --name clearwing \
    --volume "${odbcinst:?}:/etc/odbcinst.ini" \
    --volume "${apacheconf:?}:/etc/apache2/sites-enabled/000-default.conf" \
    --volume "${properties:?}:/var/www/html/atlas/config.py" \
    --volume "${firethornini:?}:/var/www/html/atlas/firethorn.ini" \
    --volume "${clearwinglogs:?}:/var/log/apache2" \
    --link "${firename:?}:${firelink:?}" \
    --link "${dataname:?}:${datalink:?}" \
    --volume "${setupdir:?}/apache-clearwing-init.sh:${setupdir:?}/apache-clearwing-init.sh" \
   firethorn/clearwing:${version:?}

docker exec clearwing /bin/sh -l -c "${setupdir:?}/apache-clearwing-init.sh"



