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


        identity=${identity:-$(date '+%H:%M:%S')}
        community=${community:-$(date '+%A %-d %B %Y')}

        source "bin/01-01-init-rest.sh"

# -----------------------------------------------------
# Check the system info.
#[root@tester]

        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            "${endpointurl:?}/system/info" \
            | bin/pp | tee system-info.json

# -----------------------------------------------------
# Load the ATLASDR1 resource.
#[root@tester]

        database=${datadata:?}
        
        source "bin/02-02-create-jdbc-space.sh" \
            "${catalogue:?} JDBC conection" \
            "jdbc:jtds:sqlserver://${datalink:?}/${database:?}" \
            "${datauser:?}" \
            "${datapass:?}" \
            "${datadriver:?}" \
            '*'
        atlasjdbc=${jdbcspace:?}

        source "bin/03-01-create-adql-space.sh" '${catalogue:?} ADQL workspace'
        atlasadql=${adqlspace:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" ${catalogue:?} 'dbo' "meta/${catalogue:?}_TablesSchema.xml"




# -----------------------------------------------------
# Create our workspace
#[root@tester]

        source "bin/04-01-create-query-space.sh" 'Test workspace'
        source "bin/04-03-import-query-schema.sh" "${atlasadql:?}" "${catalogue:?}" "${catalogue:?}"


	# -----------------------------------------------------
	# Testing TAP

	resourceid=$(basename ${atlasadql:?}) 
	query="SELECT+TOP+10+*+FROM+${catalogue:?}.atlasSource"
	format=VOTABLE
	lang=ADQL
	request=doQuery
	

        identity=${identity:-$(date '+%H:%M:%S')}
        community=${community:-$(date '+%A %-d %B %Y')}

        source "bin/01-01-init-rest.sh"


        # Get VOSI
	curl ${endpointurl:?}/tap/${resourceid:?}/tables


	# ----------------------Query test1: synchronous-------------------------------
        # Run a synchronous query
	
	curl -v -L \
	${endpointurl:?}/tap/${resourceid:?}/sync \
	-d QUERY=${query:?} \
	-d LANG=${lang:?} \
	-d MAXREC=2 \
	-d REQUEST=${request:?}

	
	# ----------------------TAP_SCHEMA generating-------------------------------

	tap_schema_user=${metauser:?}
	tap_schema_pass=${metapass:?}
	tap_schema_url=${metadataurl:?}/${metadata?} 
	tap_schema_driver=net.sourceforge.jtds.jdbc.Driver
	tap_schema_db=${metadata?}

        # Generate TAP_SCHEMA
	curl --data "url=${tap_schema_url:?}&user=${tap_schema_user:?}&pass=${tap_schema_pass:?}&driver=${tap_schema_driver:?}&catalog=${tap_schema_db:?}" ${endpointurl:?}/tap/${resourceid:?}/generateTapSchema

       echo "${catalogue:?} TAP Service: ${endpointurl:?}/tap/${resourceid:?}"
       echo "${catalogue:?} Firethorn Resource: ${endpointurl:?}${atlasadql:?}"

cat <<EOF >> ${HOME}/tap_service
http://${ip:?}:80/firethorn/tap/${resourceid:?}
EOF
   






