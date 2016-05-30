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

    echo "*** Initialising create-chain script [create-chain.sh] ***"
    source ${HOME:?}/chain.properties


    echo "*** Run our userdata ambassador. [create-chain.sh] ***"
# -----------------------------------------------------
# Run our userdata ambassador.
#[root@virtual]


    docker run \
        --detach \
        --name "${username:?}" \
        --env  "target=${userhost:?}" \
        firethorn/sql-proxy:1.1

    echo "*** Run our science data ambassador. [create-chain.sh] ***"
# -----------------------------------------------------
# Run our science data ambassador.
#[root@virtual]


    docker run \
        --detach \
        --name "${dataname:?}" \
        --env  "target=${datahost:?}" \
        firethorn/sql-proxy:1.1

# -----------------------------------------------------
# Start our PostgreSQL metadata container.
#[root@virtual]

#    source /tmp/chain.properties

#    docker run \
#        --detach \
#        --name "${metaname:?}" \
#        --env "POSTGRES_USER=${metauser:?}" \
#        --env "POSTGRES_PASSWORD=${metapass:?}" \
#       postgres



# -----------------------------------------------------
# Create our directory function.
#[root@virtual]

    directory()
        {
        local target=${1:?}

        mkdir --parents "${target:?}"

        chown 995:994 "${target:?}"
        chmod u=rwxs  "${target:?}"
        chmod g=rwxs  "${target:?}"

        chcon -t svirt_sandbox_file_t "${target:?}"

        }


    echo "*** Start our OGSA-DAI container. [create-chain.sh] ***"
# -----------------------------------------------------
# Start our OGSA-DAI container.
#[root@virtual]


    ogsatemp="/var/temp/${ogsaname:?}"
    ogsalogs="/var/logs/${ogsaname:?}"

    directory "${ogsatemp:?}"
    directory "${ogsalogs:?}"

    docker run \
        --detach \
        --publish 8081:8080 \
        --memory 512M \
        --name "${ogsaname:?}" \
        --link "${dataname:?}:${datalink:?}" \
        --link "${username:?}:${userlink:?}" \
        --volume "${ogsatemp:?}:/temp" \
        --volume "${ogsalogs:?}:/var/local/tomcat/logs" \
        firethorn/ogsadai:${version:?}


    echo "*** Create our FireThorn config. [create-chain.sh] ***"
# -----------------------------------------------------
# Create our FireThorn config.
#[root@virtual]



properties=$(mktemp)
cat > "${properties:?}" << EOF

        firethorn.ogsadai.endpoint=http://${ogsalink:?}:8080/ogsadai/services

        firethorn.limits.time.default=6000000
        firethorn.limits.time.absolute=6000000
        firethorn.limits.rows.default=${defaultrows:?}
        firethorn.limits.rows.absolute=${absoluterows:?}

        firethorn.meta.url=jdbc:jtds:sqlserver://${userlink:?}/${metadata:?}
        firethorn.meta.user=${metauser:?}
        firethorn.meta.pass=${metapass:?}
        firethorn.meta.driver=net.sourceforge.jtds.jdbc.Driver
        firethorn.meta.type=mssql

        firethorn.user.url=jdbc:jtds:sqlserver://${userlink:?}/${userdata:?}
        firethorn.user.user=${useruser:?}
        firethorn.user.pass=${userpass:?}
        firethorn.user.driver=net.sourceforge.jtds.jdbc.Driver
        firethorn.user.type=mssql


EOF

    chmod a+r "${properties:?}" 
    chcon -t svirt_sandbox_file_t "${properties:?}" 


# -----------------------------------------------------
# Create our Tomcat setenv script.
#[root@virtual]


    setenv=$(mktemp)
    cat > "${setenv:?}" << 'EOF'
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=8085"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.rmi.port=8085"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.local.only=false"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.rmi.server.hostname=192.168.122.13"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.rmi.activation.port=8086"
EOF

    chmod a+r "${setenv:?}" 
    chcon -t svirt_sandbox_file_t "${setenv:?}" 


    echo "*** Start our FireThorn container. [create-chain.sh] ***"
# -----------------------------------------------------
# Start our FireThorn container.
#[root@virtual]


    firetemp="/var/temp/${firename:?}"
    firelogs="/var/logs/${firename:?}"

    directory "${firetemp:?}"
    directory "${firelogs:?}"

    docker run \
        --detach \
        --publish 8080:8080 \
        --publish 8085:8085 \
        --name "${firename:?}" \
        --memory 512M \
        --link "${ogsaname:?}:${ogsalink:?}" \
        --link "${dataname:?}:${datalink:?}" \
        --link "${username:?}:${userlink:?}" \
        --volume "${firetemp:?}:/temp" \
        --volume "${firelogs:?}:/var/local/tomcat/logs" \
        --volume "${properties:?}:/etc/firethorn.properties" \
        --volume "${setenv:?}:/var/local/tomcat/bin/setenv.sh" \
        "firethorn/firethorn:${version:?}"


    pyrologs="/var/logs/pyrothorn"
    directory "${pyrologs:?}"

    clearwinglog=clearwing
    clearwinglogs="/var/logs/${clearwinglog:?}"

    directory "${clearwinglogs:?}"
    sleep 10

