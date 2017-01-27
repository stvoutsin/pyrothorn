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



# -------------------------TEST 1----------------------------
# Test local TWOMASS and ATLASDR1 from the same JDBC resource.
# -----------------------------------------------------------


# Configure our identity.
#[root@tester]

        identity=${identity:-$(date '+%H:%M:%S')}
        community=${community:-$(date '+%A %-d %B %Y')}

        source "bin/01-01-init-rest.sh"

# -----------------------------------------------------
# Check the system info.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            "${endpointurl:?}/system/info" \
            | bin/pp | tee /tmp/system-info.json




        source "bin/02-02-create-jdbc-space.sh" \
            'TWOMASS JDBC conection' \
            "jdbc:jtds:sqlserver://${dataname:?}/TWOMASS" \
            "${datauser:?}" \
            "${datapass:?}" \
            "${datadriver:?}" \
            '*'
        wfaujdbc=${jdbcspace:?}

        source "bin/03-01-create-adql-space.sh" 'TWOMASS ADQL workspace'
        wfauadql=${adqlspace:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${wfaujdbc:?}" "${wfauadql:?}" 'TWOMASS' 'dbo' "meta/TWOMASS_TablesSchema.xml"
        atlastwomass=${adqlschema:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${wfaujdbc:?}" "${wfauadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_TablesSchema.xml"
        atlasdr1=${adqlschema:?}

# -----------------------------------------------------
# Create a workspace and add the local TWOMASS schema.
#[root@tester]

        source "bin/04-01-create-query-space.sh"  'Test workspace'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}" 'TWOMASS' 'twomass'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}"  'ATLASDR1' 'atlasdr1'

# Create our join queries ...
#[root@tester]

#1407 rows
   cat > /tmp/join-query-1000.adql << EOF

            SELECT
               	atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
               	twomass_psc.dec as tmdec,
               	atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
               	twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 350.5 AND 351
            AND
               	atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 350.5 AND 351
            AND
               	twomass_psc.dec BETWEEN -40 AND -39
EOF

#2573 rows
    cat > /tmp/join-query-2000.adql << EOF

            SELECT
                atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
                twomass_psc.dec as tmdec,
                atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
                twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 354 AND 355
            AND
                atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 354 AND 355
            AND
                twomass_psc.dec BETWEEN -40 AND -39
EOF

 cat > /tmp/join-query-5000.adql << EOF

            SELECT
               	atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
               	twomass_psc.dec as tmdec,
               	atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
               	twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 350 AND 351
            AND
               	atlasSource.dec BETWEEN -40 AND -38
            AND
                twomass_psc.ra  BETWEEN 350 AND 351
            AND
               	twomass_psc.dec BETWEEN -40 AND -38
EOF

#>10000 rows 
    cat > /tmp/join-query-10000.adql << EOF

            SELECT
                atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
                twomass_psc.dec as tmdec,
                atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
                twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 351 AND 355
            AND
                atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 351 AND 355
            AND
                twomass_psc.dec BETWEEN -40 AND -39
EOF


# -----------------------------------------------------
# Execute our join queries.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-1000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json


        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")


	if [ "$count" -eq 1407 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 1407!=" + $count;
	fi

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-2000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$count" -eq 2573 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 2573!=" + $count;
	fi

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-5000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$count" -eq 5592 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 5592!=" + $count;
	fi

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-10000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

    
        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$count" -ge 10000 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 10000!=" + $count;
	fi





# -------------------------TEST 2----------------------------
# Test local TWOMASS and ATLASDR1 from two JDBC resources.
# -----------------------------------------------------------


# 
#[root@tester]

        source "bin/02-02-create-jdbc-space.sh" \
            'TWOMASS JDBC conection' \
            "jdbc:jtds:sqlserver://${dataname:?}/TWOMASS" \
            "${datauser:?}" \
            "${datapass:?}" \
            "${datadriver:?}" \
            '*'
        twomassjdbc=${jdbcspace:?}


        source "bin/02-02-create-jdbc-space.sh" \
            'TWOMASS JDBC conection' \
            "jdbc:jtds:sqlserver://${dataname:?}/ATLASDR1" \
            "${datauser:?}" \
            "${datapass:?}" \
            "${datadriver:?}" \
            '*'
        atlasjdbc=${jdbcspace:?}

        source "bin/03-01-create-adql-space.sh" 'TWOMASS ADQL workspace'
        wfauadql=${adqlspace:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${twomassjdbc:?}" "${wfauadql:?}" 'TWOMASS' 'dbo' "meta/TWOMASS_TablesSchema.xml"
        atlastwomass=${adqlschema:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${wfauadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_TablesSchema.xml"
        atlasdr1=${adqlschema:?}

# -----------------------------------------------------
# Create a workspace and add the local TWOMASS schema.
#[root@tester]

        source "bin/04-01-create-query-space.sh"  'Test workspace'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}" 'TWOMASS' 'twomass'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}"  'ATLASDR1' 'atlasdr1'


# Create our join queries ...
#[root@tester]

#1407 rows
   cat > /tmp/join-query-1000.adql << EOF

            SELECT
               	atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
               	twomass_psc.dec as tmdec,
               	atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
               	twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 350.5 AND 351
            AND
               	atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 350.5 AND 351
            AND
               	twomass_psc.dec BETWEEN -40 AND -39
EOF

#2573 rows
    cat > /tmp/join-query-2000.adql << EOF

            SELECT
                atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
                twomass_psc.dec as tmdec,
                atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
                twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 354 AND 355
            AND
                atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 354 AND 355
            AND
                twomass_psc.dec BETWEEN -40 AND -39
EOF

 cat > /tmp/join-query-5000.adql << EOF

            SELECT
               	atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
               	twomass_psc.dec as tmdec,
               	atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
               	twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 350 AND 351
            AND
               	atlasSource.dec BETWEEN -40 AND -38
            AND
                twomass_psc.ra  BETWEEN 350 AND 351
            AND
               	twomass_psc.dec BETWEEN -40 AND -38
EOF

#>10000 rows 
    cat > /tmp/join-query-10000.adql << EOF

            SELECT
                atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
                twomass_psc.dec as tmdec,
                atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                twomass_psc
            ON
                twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 351 AND 355
            AND
                atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 351 AND 355
            AND
                twomass_psc.dec BETWEEN -40 AND -39
EOF


# -----------------------------------------------------
# Execute our join queries.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-1000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json


        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")


	if [ "$count" -eq 1407 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 1407!=" + $count;
	fi

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-2000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$count" -eq 2573 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 2573!=" + $count;
	fi

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-5000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$count" -eq 5592 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 5592!=" + $count;
	fi

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-10000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

    
        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$count" -ge 10000 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 10000!=" + $count;
	fi















# -------------------------TEST 3-----
# Test ATLAS joined with GAVO.twomass
# ------------------------------------


        identity=${identity:-$(date '+%H:%M:%S')}
        community=${community:-$(date '+%A %-d %B %Y')}

        source "bin/01-01-init-rest.sh"

# -----------------------------------------------------
# Check the system info.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            "${endpointurl:?}/system/info" \
            | bin/pp | tee /tmp/system-info.json

# -----------------------------------------------------
# Load the local TWOMASS resource.
#[root@tester]

        source "bin/02-02-create-jdbc-space.sh" \
            'TWOMASS JDBC conection' \
            "jdbc:jtds:sqlserver://${dataname:?}/TWOMASS" \
            "${datauser:?}" \
            "${datapass:?}" \
            "${datadriver:?}" \
            '*'
        wfaujdbc=${jdbcspace:?}

        source "bin/03-01-create-adql-space.sh" 'TWOMASS ADQL workspace'
        wfauadql=${adqlspace:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${wfaujdbc:?}" "${wfauadql:?}" 'TWOMASS' 'dbo' "meta/TWOMASS_TablesSchema.xml"
        source "bin/03-04-import-jdbc-metadoc.sh" "${wfaujdbc:?}" "${wfauadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_TablesSchema.xml"

# -----------------------------------------------------
# Create the GAVO TWOMASS resource.
#[root@tester]

        #
        # Create the IvoaResource
        source "bin/02-03-create-ivoa-space.sh" \
            'GAVO TAP service' \
            'http://dc.zah.uni-heidelberg.de/__system__/tap/run/tap'
        gavoivoa=${ivoaspace:?}

        #
        # Import the static VOSI file
        vosifile='vosi/gavo/gavo-tableset.xml'
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --form   "vosi.tableset=@${vosifile:?}" \
            "${endpointurl:?}/${gavoivoa:?}/vosi/import" \
            | bin/pp

        #
        # Find the Gavo twomass schema
        findname=twomass
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${findname:?}" \
            "${endpointurl:?}/${gavoivoa:?}/schemas/select" \
            | bin/pp | tee /tmp/gavo-schema.json

        gavoschema=$(
            cat /tmp/gavo-schema.json | self
            )

# -----------------------------------------------------
# Create a workspace and add the local TWOMASS schema.
#[root@tester]

        source "bin/04-01-create-query-space.sh"  'Test workspace'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}" 'TWOMASS' 'wfau'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}" 'ATLASDR1' 'atlas'

# -----------------------------------------------------
# Add the GAVO TWOMASS schema to our workspace.
#[root@tester]

        gavoname=gavo
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "urn:adql.copy.depth=${adqlcopydepth:-THIN}" \
            --data   "adql.resource.schema.import.name=${gavoname:?}" \
            --data   "adql.resource.schema.import.base=${gavoschema:?}" \
            "${endpointurl:?}/${queryspace:?}/schemas/import" \
            | bin/pp | tee /tmp/query-schema.json


# -----------------------------------------------------
# Test queries ...
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data "adql.query.input=SELECT TOP 2000 designation, ra, dec FROM wfau.twomass_psc WHERE (ra BETWEEN 0 AND 0.5) AND (dec BETWEEN 0 AND 0.5)" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/wfau-query.json

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data "adql.query.input=SELECT TOP 2000 mainid AS designation, raj2000 AS ra, dej2000 AS dec FROM gavo.data WHERE (raj2000 BETWEEN 0 AND 0.5) AND (dej2000 BETWEEN 0 AND 0.5)" \" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/gavo-query.json

       
        gavocount=$(cat /tmp/gavo-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
        wfaucount=$(cat /tmp/wfau-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$gavocount" -eq "$wfaucount" ]; then
	   echo "SUCCESS! Gavo and wfau twomass areas tested are equal";
	else	
	   echo "FAILED! Gavo and wfau twomass areas tested are NOT equal";
	fi


        #
        # Get URLs for the results as VOTable
        wfaudata=$(cat /tmp/wfau-query.json | votable)
        gavodata=$(cat /tmp/gavo-query.json | votable)


        #
        # Get the results as VOTable files
        curl --silent "${wfaudata:?}" | xmlstarlet fo > /tmp/wfau-data.xml
        curl --silent "${gavodata:?}" | xmlstarlet fo > /tmp/gavo-data.xml

        #
        # Remove XML namespaces
        sed -i 's#<VOTABLE[^>]*>#<VOTABLE>#' /tmp/wfau-data.xml
        sed -i 's#<VOTABLE[^>]*>#<VOTABLE>#' /tmp/gavo-data.xml


# -----------------------------------------------------
# Create our join query ...
#[root@tester]


    cat > /tmp/join-query.adql << EOF

            SELECT
                atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.raj2000  as tmra,
                twomass_psc.dej2000 as tmdec,
                atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlas.atlasSource
            JOIN
                atlasSourceXtwomass_psc
            ON
                atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            JOIN
                gavo.data AS twomass_psc
            ON
                twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            WHERE
                atlasSource.ra  BETWEEN 351 AND 355
            AND
                atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.raj2000  BETWEEN 351 AND 355
            AND
                twomass_psc.dej2000 BETWEEN -40 AND -39

EOF

# -----------------------------------------------------
# Execute our join query.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json



        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
    
	if [ "$count" -eq 4100 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 4100!=" + $count;
	fi








# -------------------------TEST 4-------------------
# Test local TWOMASS joined with GAIADR1.gaiasource 
# --------------------------------------------------


        identity=${identity:-$(date '+%H:%M:%S')}
        community=${community:-$(date '+%A %-d %B %Y')}

        source "bin/01-01-init-rest.sh"

# -----------------------------------------------------
# Check the system info.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            "${endpointurl:?}/system/info" \
            | bin/pp | tee /tmp/system-info.json

# -----------------------------------------------------
# Load the local TWOMASS resource.
#[root@tester]

        source "bin/02-02-create-jdbc-space.sh" \
            'TWOMASS JDBC conection' \
            "jdbc:jtds:sqlserver://${dataname:?}/TWOMASS" \
            "${datauser:?}" \
            "${datapass:?}" \
            "${datadriver:?}" \
            '*'
        wfaujdbc=${jdbcspace:?}

        source "bin/03-01-create-adql-space.sh" 'TWOMASS ADQL workspace'
        wfauadql=${adqlspace:?}

        source "bin/03-04-import-jdbc-metadoc.sh" "${wfaujdbc:?}" "${wfauadql:?}" 'TWOMASS' 'dbo' "meta/TWOMASS_TablesSchema.xml"
        source "bin/03-04-import-jdbc-metadoc.sh" "${wfaujdbc:?}" "${wfauadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_TablesSchema.xml"

# --------------------------------------
# Create the GAIA TAP resource.
#[root@tester]

        #
        # Create the IvoaResource
        source "bin/02-03-create-ivoa-space.sh" \
            'GAIA TAP service' \
            'http://gea.esac.esa.int/tap-server/tap'
        gaiaivoa=${ivoaspace:?}

        #
        # Import the static VOSI file
        vosifile='vosi/gaia/gaia-tableset.xml'
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --form   "vosi.tableset=@${vosifile:?}" \
            "${endpointurl:?}/${gaiaivoa:?}/vosi/import" \
            | bin/pp

        #
        # Find the Gaia DR1 schema
        findname=gaiadr1
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${findname:?}" \
            "${endpointurl:?}/${gaiaivoa:?}/schemas/select" \
            | bin/pp | tee /tmp/gaia-schema.json

        gaiaschema=$(
            cat /tmp/gaia-schema.json | self
            )

# -----------------------------------------------------
# Create a workspace and add the local TWOMASS schema.
#[root@tester]

        source "bin/04-01-create-query-space.sh"  'Test workspace'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}" 'TWOMASS' 'wfau'
        source "bin/04-03-import-query-schema.sh" "${wfauadql:?}" 'ATLASDR1' 'atlas'

# -----------------------------------------------------
# Add the Gaia DR1 schema to our workspace.
#[root@tester]

        gaianame=gaia
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "urn:adql.copy.depth=${adqlcopydepth:-THIN}" \
            --data   "adql.resource.schema.import.name=${gaianame:?}" \
            --data   "adql.resource.schema.import.base=${gaiaschema:?}" \
            "${endpointurl:?}/${queryspace:?}/schemas/import" \
            | bin/pp | tee /tmp/query-schema.json

# -----------------------------------------------------
# Test queries ...
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data "adql.query.input=SELECT TOP 2000 designation, ra, dec FROM wfau.twomass_psc WHERE (ra BETWEEN 0 AND 0.5) AND (dec BETWEEN 0 AND 0.5)" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/wfau-query.json


        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data "adql.query.input=SELECT TOP 2000 designation, ra, dec  FROM gaia.tmass_original_valid WHERE (ra BETWEEN 0 AND 0.5) AND (dec BETWEEN 0 AND 0.5)" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/gaia-query.json

        gaiacount=$(cat /tmp/gaia-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
        wfaucount=$(cat /tmp/wfau-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")

	if [ "$gaiacount" -eq "$wfaucount" ]; then
	   echo "SUCCESS! Gavo and wfau twomass areas tested are equal";
	else	
	   echo "FAILED! Gavo and wfau twomass areas tested are NOT equal";
	fi



        #
        # Get URLs for the results as VOTable
        wfaudata=$(cat /tmp/wfau-query.json | votable)
        gaiadata=$(cat /tmp/gaia-query.json | votable)

        #
        # Get the results as VOTable files
        curl --silent "${wfaudata:?}" | xmlstarlet fo > /tmp/wfau-data.xml
        curl --silent "${gaiadata:?}" | xmlstarlet fo > /tmp/gaia-data.xml


# -----------------------------------------------------
# Create our join query ...
#[root@tester]


#2212 rows
    cat > /tmp/join-query.adql << EOF

    SELECT
        gaia.tmass_best_neighbour.original_ext_source_id AS gaia_ident,
        wfau.twomass_psc.designation                     AS wfau_ident,

        gaia.tmass_best_neighbour.source_id              AS best_source_id,
        gaia.gaia_source.source_id                       AS gaia_source_id,

        wfau.twomass_psc.ra                              AS wfau_ra,
        gaia.gaia_source.ra                              AS gaia_ra,

        wfau.twomass_psc.dec                             AS wfau_dec,
        gaia.gaia_source.dec                             AS gaia_dec

    FROM
        gaia.gaia_source,
        gaia.tmass_best_neighbour,
        wfau.twomass_psc

    WHERE
        gaia.tmass_best_neighbour.source_id = gaia.gaia_source.source_id
    AND
        gaia.tmass_best_neighbour.original_ext_source_id = wfau.twomass_psc.designation
    AND
        gaia.gaia_source.ra  BETWEEN 0 AND 1.25
    AND
        gaia.gaia_source.dec BETWEEN 0 AND 1.25
    AND
        wfau.twomass_psc.ra  BETWEEN 0 AND 1.25
    AND
        wfau.twomass_psc.dec BETWEEN 0 AND 1.25

EOF

#5594
cat > /tmp/join-query-2.adql << EOF

    SELECT
        gaia.tmass_best_neighbour.original_ext_source_id AS gaia_ident,
        wfau.twomass_psc.designation                     AS wfau_ident,

        gaia.tmass_best_neighbour.source_id              AS best_source_id,
        gaia.gaia_source.source_id                       AS gaia_source_id,

        wfau.twomass_psc.ra                              AS wfau_ra,
        gaia.gaia_source.ra                              AS gaia_ra,

        wfau.twomass_psc.dec                             AS wfau_dec,
        gaia.gaia_source.dec                             AS gaia_dec

    FROM
        gaia.gaia_source,
        gaia.tmass_best_neighbour,
        wfau.twomass_psc

    WHERE
        gaia.tmass_best_neighbour.source_id = gaia.gaia_source.source_id
    AND
        gaia.tmass_best_neighbour.original_ext_source_id = wfau.twomass_psc.designation
    AND
        gaia.gaia_source.ra  BETWEEN 0 AND 3.25
    AND
        gaia.gaia_source.dec BETWEEN 0 AND 1.25
    AND
        wfau.twomass_psc.ra  BETWEEN 0 AND 3.25
    AND
        wfau.twomass_psc.dec BETWEEN 0 AND 1.25

EOF


#10000 (TRUNCATED)
cat > /tmp/join-query-3.adql << EOF

    SELECT
        gaia.tmass_best_neighbour.original_ext_source_id AS gaia_ident,
        wfau.twomass_psc.designation                     AS wfau_ident,

        gaia.tmass_best_neighbour.source_id              AS best_source_id,
        gaia.gaia_source.source_id                       AS gaia_source_id,

        wfau.twomass_psc.ra                              AS wfau_ra,
        gaia.gaia_source.ra                              AS gaia_ra,

        wfau.twomass_psc.dec                             AS wfau_dec,
        gaia.gaia_source.dec                             AS gaia_dec

    FROM
        gaia.gaia_source,
        gaia.tmass_best_neighbour,
        wfau.twomass_psc

    WHERE
        gaia.tmass_best_neighbour.source_id = gaia.gaia_source.source_id
    AND
        gaia.tmass_best_neighbour.original_ext_source_id = wfau.twomass_psc.designation
    AND
        gaia.gaia_source.ra  BETWEEN 0 AND 3.25
    AND
        gaia.gaia_source.dec BETWEEN 0 AND 3.25
    AND
        wfau.twomass_psc.ra  BETWEEN 0 AND 3.25
    AND
        wfau.twomass_psc.dec BETWEEN 0 AND 3.25

EOF


#2212 rows
    cat > /tmp/join-query-4.adql << EOF


    SELECT
        gaia.tmass_best_neighbour.original_ext_source_id AS gaia_ident,
        wfau.twomass_psc.designation                     AS wfau_ident,

        gaia.tmass_best_neighbour.source_id              AS best_source_id,
        gaia.gaia_source.source_id                       AS gaia_source_id,

        wfau.twomass_psc.ra                              AS wfau_ra,
        gaia.gaia_source.ra                              AS gaia_ra,

        wfau.twomass_psc.dec                             AS wfau_dec,
        gaia.gaia_source.dec                             AS gaia_dec
    FROM
        gaia.gaia_source
    JOIN
        gaia.tmass_best_neighbour
    ON
        gaia.tmass_best_neighbour.source_id = gaia.gaia_source.source_id
    JOIN
        wfau.twomass_psc
    ON
        gaia.tmass_best_neighbour.original_ext_source_id = wfau.twomass_psc.designation
    WHERE
        gaia.gaia_source.ra  BETWEEN 0 AND 1.25
    AND
        gaia.gaia_source.dec BETWEEN 0 AND 1.25
    AND
        wfau.twomass_psc.ra  BETWEEN 0 AND 1.25
    AND
        wfau.twomass_psc.dec BETWEEN 0 AND 1.25

EOF

# -----------------------------------------------------
# Execute our join query.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
    
	if [ "$count" -eq 2212 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 2212!=" + $count;
	fi





        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-2.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
    
	if [ "$count" -eq 5594 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 5594!=" + $count;
	fi




        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-3.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json


        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
    

	if [ "$count" -ge 10000 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 10000!=" + $count;
	fi




        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-4.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
    
	if [ "$count" -eq "2212" ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 2212!=" + $count;
	fi








# -------------------------TEST 5-------------------
# Test GAVO twomass joined with GAIADR1.gaiasource 
# --------------------------------------------------


        identity=${identity:-$(date '+%H:%M:%S')}
        community=${community:-$(date '+%A %-d %B %Y')}

        source "bin/01-01-init-rest.sh"

# -----------------------------------------------------
# Check the system info.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            "${endpointurl:?}/system/info" \
            | bin/pp | tee /tmp/system-info.json


# --------------------------------------
# Create the GAIA TAP resource.
#[root@tester]

        #
        # Create the IvoaResource
        source "bin/02-03-create-ivoa-space.sh" \
            'GAIA TAP service' \
            'http://gea.esac.esa.int/tap-server/tap'
        gaiaivoa=${ivoaspace:?}

        #
        # Import the static VOSI file
        vosifile='vosi/gaia/gaia-tableset.xml'
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --form   "vosi.tableset=@${vosifile:?}" \
            "${endpointurl:?}/${gaiaivoa:?}/vosi/import" \
            | bin/pp

        #
        # Find the Gaia DR1 schema
        findname=gaiadr1
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${findname:?}" \
            "${endpointurl:?}/${gaiaivoa:?}/schemas/select" \
            | bin/pp | tee /tmp/gaia-schema.json

        gaiaschema=$(
            cat /tmp/gaia-schema.json | self
            )


        #
        # Create the IvoaResource
        source "bin/02-03-create-ivoa-space.sh" \
            'GAVO TAP service' \
            'http://dc.zah.uni-heidelberg.de/__system__/tap/run/tap'
        gavoivoa=${ivoaspace:?}

        #
        # Import the static VOSI file
        vosifile='vosi/gavo/gavo-tableset.xml'
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --form   "vosi.tableset=@${vosifile:?}" \
            "${endpointurl:?}/${gavoivoa:?}/vosi/import" \
            | bin/pp

        #
        # Find the Gavo twomass schema
        findname=twomass
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${findname:?}" \
            "${endpointurl:?}/${gavoivoa:?}/schemas/select" \
            | bin/pp | tee /tmp/gavo-schema.json

        gavoschema=$(
            cat /tmp/gavo-schema.json | self
            )

# -----------------------------------------------------
# Create a workspace and add the local TWOMASS schema.
#[root@tester]

        source "bin/04-01-create-query-space.sh"  'Test workspace'

# -----------------------------------------------------
# Add the GAVO TWOMASS schema to our workspace.
#[root@tester]

        gavoname=gavo
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "urn:adql.copy.depth=${adqlcopydepth:-THIN}" \
            --data   "adql.resource.schema.import.name=${gavoname:?}" \
            --data   "adql.resource.schema.import.base=${gavoschema:?}" \
            "${endpointurl:?}/${queryspace:?}/schemas/import" \
            | bin/pp | tee /tmp/query-schema.json

# -----------------------------------------------------
# Add the Gaia DR1 schema to our workspace.
#[root@tester]

        gaianame=gaia
        curl \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "urn:adql.copy.depth=${adqlcopydepth:-THIN}" \
            --data   "adql.resource.schema.import.name=${gaianame:?}" \
            --data   "adql.resource.schema.import.base=${gaiaschema:?}" \
            "${endpointurl:?}/${queryspace:?}/schemas/import" \
            | bin/pp | tee /tmp/query-schema.json


# -----------------------------------------------------
# Create our join query ...
#[root@tester]


#2212 rows
    cat > /tmp/join-query.adql << EOF

    SELECT
        gaia.tmass_best_neighbour.original_ext_source_id AS gaia_ident,
        twomass_psc.mainid                     AS gavo_ident,

        gaia.tmass_best_neighbour.source_id              AS best_source_id,
        gaia.gaia_source.source_id                       AS gaia_source_id,

        twomass_psc.raj2000                              AS tmra,
        gaia.gaia_source.ra                              AS gaia_ra,

        twomass_psc.dej2000                             AS tmdec,
        gaia.gaia_source.dec                             AS gaia_dec

    FROM
        gaia.gaia_source,
        gaia.tmass_best_neighbour,
        gavo.data AS twomass_psc

    WHERE
        gaia.tmass_best_neighbour.source_id = gaia.gaia_source.source_id
    AND
        gaia.tmass_best_neighbour.original_ext_source_id = twomass_psc.mainid
    AND
        gaia.gaia_source.ra  BETWEEN 0 AND 3.25
    AND
        gaia.gaia_source.dec BETWEEN 0 AND 3.25
    AND
        twomass_psc.raj2000   BETWEEN 0 AND 3.25
    AND
        twomass_psc.dej2000 BETWEEN 0 AND 3.25



EOF


# -----------------------------------------------------
# Execute our join query.
#[root@tester]

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        count=$(cat /tmp/join-query.json | python3 -c "import sys;import json; print (json.load(sys.stdin)['results']['count'])")
    
	if [ "$count" -eq 2212 ]; then
	   echo "SUCCESS!";
	else	
	   echo "FAILED! 2212!=" + $count;
	fi




