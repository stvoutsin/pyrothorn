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

echo "*** Initialising build scripts [setup-pyro.sh] ***"

source ${HOME:?}/chain.properties

echo "*** Create sql-proxy for stored queries database [setup-pyro.sh] ***"
# -----------------------------------------
# Create sql-proxy for stored queries database
#
docker run \
    --detach \
    --name "${storedqueriesname?}" \
    --env  "target=${storedquerieshost:?}" \
    firethorn/sql-proxy:1

echo "*** Run pyrosl MySQL container [setup-pyro.sh] ***"
# -----------------------------------------
# Run pyrosl MySQL container
#
docker run -d -t --name ${pyrosqlname:?} -p 3306:3306 firethorn/pyrosql


