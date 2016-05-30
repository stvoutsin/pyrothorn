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
mkdir logs

identity=${identity:-$(date '+%H:%M:%S')}
community=${community:-$(date '+%A %-d %B %Y')}

source "bin/01-01-init-rest.sh" 

database=ATLASDR1

source "bin/02-02-create-jdbc-space.sh" \
    'Atlas JDBC conection' \
    "jdbc:jtds:sqlserver://${datalink:?}/${database:?}" \
    "${datauser:?}" \
    "${datapass:?}" \
    "${datadriver:?}" \
    '*'
atlasjdbc=${jdbcspace:?}

source "bin/03-01-create-adql-space.sh" 'Atlas ADQL workspace'
atlasadql=${adqlspace:?}

source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_AtlasSource.xml" 
atlasschema=${adqlschema:?}

source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_AtlasTwomass.xml" 
atlascross=${adqlschema:?}

source "bin/04-01-create-query-space.sh" 'Test workspace'

source "bin/04-03-import-query-schema.sh" "${atlasadql:?}" 'ATLASDR1' 'atlas'
source "bin/04-03-import-query-schema.sh" "${atlasadql:?}" 'TWOMASS'  'twomass'

source "bin/04-03-create-query-schema.sh" 

echo "Press [CTRL+C] to stop.."

while :
do



    adqltext="SELECT atlasSource.ra, atlasSource.dec FROM atlas.atlasSource WHERE atlasSource.ra  BETWEEN 354 AND 355 AND atlasSource.dec BETWEEN -40 AND -39"

    echo "Running query.."
    #
    # Create the query.
    curl \
    --header "firethorn.auth.identity:${identity:?}" \
    --header "firethorn.auth.community:${community:?}" \
    --data   "adql.schema.query.create.mode=AUTO" \
    --data-urlencode "adql.schema.query.create.query=${adqltext:?}" \
    "${endpointurl:?}/${queryschema:?}/queries/create" \
     | bin/pp | tee query-job.json

    queryident=$(
    cat query-job.json | self | node
    )

    # Create the query.
    curl \
    --header "firethorn.auth.identity:${identity:?}" \
    --header "firethorn.auth.community:${community:?}" \
    --data   "adql.schema.query.create.mode=AUTO" \
    --data-urlencode "adql.schema.query.create.query=${adqltext:?}" \
    "${endpointurl:?}/${queryschema:?}/queries/create" \
     | bin/pp | tee query-job.json

    queryident=$(
    cat query-job.json | self | node
    )
 
    curl \
    --header "firethorn.auth.identity:${identity:?}" \
    --header "firethorn.auth.community:${community:?}" \
    --data-urlencode "adql.query.update.status=RUNNING" \
    "${endpointurl:?}/${queryident:?}" 
            
    sleep 1
done
 
