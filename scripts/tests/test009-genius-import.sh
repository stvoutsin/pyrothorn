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
            | bin/pp | tee system-info.json


# -----------------------------------------------------
# Load the ATLASDR1 resource.
#[root@tester]

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

        source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'ATLASDR1' 'dbo' "meta/ATLASDR1_TablesSchema.xml"
        source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'TWOMASS' 'dbo' "meta/TWOMASS_TablesSchema.xml" 
	source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'VHSDR1' 'dbo' "meta/VHSDR1_TablesSchema.xml" 
	source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'SDSSDR9' 'dbo' "meta/SDSSDR9_TablesSchema.xml" 
	source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'BESTDR9' 'dbo' "meta/BESTDR9_TablesSchema.xml" 
	source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'VIKINGDR3' 'dbo' "meta/VIKINGDR3_TablesSchema.xml" 
	source "bin/03-04-import-jdbc-metadoc.sh" "${atlasjdbc:?}" "${atlasadql:?}" 'WISE' 'dbo' "meta/WISE_TablesSchema.xml" 


# --------------------------------------
# Create the GAIA resource.
#[root@tester]

        #
        # Create the IvoaResource
        source "bin/02-03-create-ivoa-space.sh" \
            'GAIA TAP service' \
            'http://gea.esac.esa.int/tap-server/tap'

        #
        # Import the static VOSI file
        vosifile='vosi/gaia/gaia-tableset.xml'
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --form   "vosi.tableset=@${vosifile:?}" \
            "${endpointurl:?}/${ivoaspace:?}/vosi/import" \
            | bin/pp



        gaiaspace=${ivoaspace:?}
        gaiaschemaname=gaiadr1
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${gaiaschemaname:?}" \
            "${endpointurl:?}/${gaiaspace:?}/schemas/select" \
            | bin/pp | tee gaia-schema.json


        gaiaspace=${ivoaspace:?}
        gaiaschemaname=public
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${gaiaschemaname:?}" \
            "${endpointurl:?}/${gaiaspace:?}/schemas/select" \
            | bin/pp | tee gaia-schema.json

        gaiaschema=$(
            cat gaia-schema.json | self
            )




# --------------------------------------
# Create the GAVO resource.
#[root@tester]

        #
        # Create the IvoaResource
        source "bin/02-03-create-ivoa-space.sh" \
            'GAVO TAP service' \
            'http://dc.zah.uni-heidelberg.de/__system__/tap/run/tap'

        #
        # Import the static VOSI file
        vosifile='vosi/gavo/gavo-tableset.xml'
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --form   "vosi.tableset=@${vosifile:?}" \
            "${endpointurl:?}/${ivoaspace:?}/vosi/import" \
            | bin/pp

        #
        # Find the twomass schema
        gavospace=${ivoaspace:?}
        gavoschemaname=icecube
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "ivoa.resource.schema.name=${gavoschemaname:?}" \
            "${endpointurl:?}/${gavospace:?}/schemas/select" \
            | bin/pp | tee gavo-schema.json

        gavoschema=$(
            cat gavo-schema.json | self
            )

# --------------------------------------
# Import IVOA resources.

	adqlname=ICECUBE
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "urn:adql.copy.depth=${adqlcopydepth:-THIN}" \
            --data   "adql.resource.schema.import.name=${adqlname:?}" \
            --data   "adql.resource.schema.import.base=${gavoschema:?}" \
            "${endpointurl:?}/${adqlspace:?}/schemas/import" \
            | bin/pp | tee gavo-schema-import.json



        adqlname=GACS
        curl \
            --silent \
            --header "firethorn.auth.identity:${identity:?}" \
            --header "firethorn.auth.community:${community:?}" \
            --data   "urn:adql.copy.depth=${adqlcopydepth:-THIN}" \
            --data   "adql.resource.schema.import.name=${adqlname:?}" \
            --data   "adql.resource.schema.import.base=${gaiaschema:?}" \
            "${endpointurl:?}/${adqlspace:?}/schemas/import" \
            | bin/pp | tee gaia-schema-import.json

        mainschema=$(
            cat gaia-schema-import.json | self
            )


cat <<EOF >> ${HOME}/adqlresource
${endpointurl:?}/${adqlspace:?}
EOF
   

cat <<EOF >> ${HOME}/adqlschema
${mainschema:?}
EOF
   
exit
