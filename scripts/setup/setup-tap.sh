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
catalogue=$1

if [ "$catalogue" != "DEFAULT" ]
  then
    echo "Building TAP service for the supplied catalogue:" + ${catalogue:?}
  else
    catalogue=${testrundatabase:?}
    echo "No catalogue given.. Using catalogue from config:" + ${catalogue:?}
fi

source ${HOME:?}/chain.properties

setupdir="${HOME:?}/setup"

chmod a+r "${HOME:?}/tap_service"

echo "*** Running tap setup script ***"

chcon -t svirt_sandbox_file_t "${setupdir:?}/build-tap.sh" 

chmod a+r "${setupdir:?}/build-tap.sh"

homedir="${HOME:?}"

touch "${HOME:?}/tap_service"
>tap_service
chcon -t svirt_sandbox_file_t "${HOME:?}/tap_service" 

chmod a+r "${HOME:?}/tap_service"

ip=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)

# -----------------------------------------------------
# Start our test container.
#[user@desktop]

    source "${HOME:?}/chain.properties"
    docker run \
        --detach \
        --memory 512M \
        --volume "${HOME:?}/tap_service:${HOME:?}/tap_service" \
        --volume "${setupdir:?}/build-tap.sh:${setupdir:?}/build-tap.sh" \
        --env "datadata=${datadata:?}" \
        --env "datalink=${datalink:?}" \
        --env "datauser=${datauser:?}" \
        --env "datapass=${datapass:?}" \
        --env "datadriver=${datadriver:?}" \
        --env "metadataurl=jdbc:jtds:sqlserver://${userlink:?}" \
        --env "metauser=${metauser:?}" \
        --env "metapass=${metapass:?}" \
        --env "metadata=${metadata?}" \
        --env "endpointurl=http://${firelink:?}:8080/firethorn" \
        --env "catalogue=${catalogue:?}" \
        --env "ip=${ip:?}" \
        --link "${firename:?}:${firelink:?}" \
        "firethorn/tester:1.1" \
        bash -C ${setupdir:?}/build-tap.sh






