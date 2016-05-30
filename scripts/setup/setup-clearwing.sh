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


clearwinglog=clearwing
clearwinglogs="/var/logs/${clearwinglog:?}"
setupdir="${HOME:?}/setup"


source "${HOME:?}/chain.properties"

chcon -t svirt_sandbox_file_t "${setupdir:?}/apache-clearwing-init.sh" 
chmod +x "${setupdir:?}/apache-clearwing-init.sh"


chmod +x "${HOME:?}/setup/build-clearwing.sh"
chcon -t svirt_sandbox_file_t "${HOME:?}/setup/build-clearwing.sh" 
 
docker rm -f clearwing
docker rm -f webpybuilder

# ----------------------------------------------------
# Run builder

    docker run \
        -it \
        --name webpybuilder \
        --env "branch=${branch:?}" \
        --env "version=${version:?}" \
        --env "clearwing_version=${input_variable:?}" \
        --volume /var/local/cache:/cache \
        --volume /var/local/projects:/projects \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        --volume ${HOME:?}/setup/build-clearwing.sh:${HOME:?}/build-clearwing.sh \
        --volume "${HOME:?}/chain.properties:/root/chain.properties" \
        firethorn/builder:1 \
        bash ${HOME:?}/build-clearwing.sh


