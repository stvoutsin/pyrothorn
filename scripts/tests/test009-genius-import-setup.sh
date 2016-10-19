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


    source ${HOME:?}/chain.properties

    testname=tester

    chmod a+r "${HOME:?}/tests/test009-genius-import.sh" 
    chcon -t svirt_sandbox_file_t "${HOME:?}/tests/test009-genius-import.sh" 
    testerlogs="/var/logs/tester"

    directory "${testerlogs:?}"

    chmod a+r "${HOME:?}/adqlresource"
    touch "${HOME:?}/adqlresource"
    >adqlresource
    chcon -t svirt_sandbox_file_t "${HOME:?}/adqlresource" 

    chmod a+r "${HOME:?}/adqlschema"
    touch "${HOME:?}/adqlschema"
    >adqlschema
    chcon -t svirt_sandbox_file_t "${HOME:?}/adqlschema" 


    echo "*** Running Genius Resource import ***"

    docker run \
        --detach \
        --volume "${HOME:?}/tests/test009-genius-import.sh:/scripts/test009-genius-import.sh" \
        --volume "${HOME:?}/adqlresource:${HOME:?}/adqlresource" \
        --volume "${HOME:?}/adqlschema:${HOME:?}/adqlschema" \
        --name "${testname:?}" \
        --env "datalink=${datalink:?}" \
        --env "datauser=${datauser:?}" \
        --env "datapass=${datapass:?}" \
        --env "datadriver=${datadriver:?}" \
        --env "endpointurl=http://${firelink:?}:8080/firethorn" \
        --link "${firename:?}:${firelink:?}" \
        --volume "${testerlogs:?}:${HOME:?}/logs" \
        "firethorn/tester:${version:?}" \
        bash  -c 'source /scripts/test009-genius-import.sh 2>&1 | tee /root/logs/output.log'

