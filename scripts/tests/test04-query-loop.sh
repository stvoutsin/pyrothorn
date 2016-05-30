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

    echo "*** Initialising test03 [test03-hist-catalogue.sh] ***"
    source ${HOME:?}/chain.properties

    testname=tester

    chmod a+r "${HOME:?}/tests/test04-nohup.sh" 
    chcon -t svirt_sandbox_file_t "${HOME:?}/tests/test04-nohup.sh" 
    testerlogs="/var/logs/tester"

    directory "${testerlogs:?}"

    echo "*** Running tester (Query loop) [test03-hist-catalogue.sh] ***"

    docker run \
        --detach \
        --volume "${HOME:?}/tests/test04-nohup.sh:/scripts/test04-nohup.sh" \
        --name "${testname:?}" \
        --env "datalink=${datalink:?}" \
        --env "datauser=${datauser:?}" \
        --env "datapass=${datapass:?}" \
        --env "datadriver=${datadriver:?}" \
        --env "endpointurl=http://${firelink:?}:8080/firethorn" \
        --link "${firename:?}:${firelink:?}" \
        --volume "${testerlogs:?}:${HOME:?}/logs" \
        "firethorn/tester:${version:?}" \
        bash  -c 'source /scripts/test04-nohup.sh 2>&1 | tee /root/logs/output.log'

