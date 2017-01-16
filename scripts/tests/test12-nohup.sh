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

# -----------------------------------------------------
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

# -----------------------------------------------------
# Test local TWOMASS and ATLASDR1 from the same JDBC resource.
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

#2573 rows
   cat > /tmp/join-query.adql << EOF

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

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-2000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-5000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-10000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

    







# -----------------------------------------------------
# Test local TWOMASS and ATLASDR1 from two JDBC resources.
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

#2573 rows
   cat > /tmp/join-query.adql << EOF

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


# Implicit join
    cat > /tmp/join-query-implicit.adql << EOF

            SELECT
                atlasSource.ra  as atra,
                atlasSource.dec as atdec,
                twomass_psc.ra  as tmra,
                twomass_psc.dec as tmdec,
                atlasSourceXtwomass_psc.distanceMins as dist
            FROM
                atlasSource
                twomass_psc
                atlasSourceXtwomass_psc
	    WHERE
                twomass_psc.pts_key = atlasSourceXtwomass_psc.slaveObjID
            AND
                atlasSource.ra  BETWEEN 351 AND 355
            AND
		atlasSource.sourceID = atlasSourceXtwomass_psc.masterObjID 
            AND
                atlasSource.dec BETWEEN -40 AND -39
            AND
                twomass_psc.ra  BETWEEN 351 AND 355
            AND
                twomass_psc.dec BETWEEN -40 AND -39
	    ORDER BY
                atra ASC
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

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-2000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-5000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json

        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-10000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query.json
    
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data-urlencode "adql.query.input@/tmp/join-query-10000.adql" \
            --data "adql.query.status.next=COMPLETED" \
            --data "adql.query.wait.time=600000" \
            "${endpointurl:?}/${queryspace:?}/queries/create" \
            | bin/pp | tee /tmp/join-query-implicit.json
