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

homedir="${HOME:?}"
setupdir="$(pwd)/setup"
clearwingip=$1
tapserviceip=$2

chcon -t svirt_sandbox_file_t "${setupdir:?}/apache-proxy-config-script.sh" 
chmod +x "${setupdir:?}/apache-proxy-config-script.sh"

firepachelogs="/var/logs/firepache"

directory "${firepachelogs:?}"

docker run -p 80:80 --name firepache  --memory 512M --volume "${firepachelogs:?}:/var/log/apache2" --volume "${setupdir:?}/apache-proxy-config-script.sh:${setupdir:?}/apache-proxy-config-script.sh" --env "tapserviceip=${tapserviceip:?}" --env "clearwingip=${clearwingip:?}" -d firethorn/apache:${version:?} 

docker exec  firepache /bin/sh -l -c ${setupdir:?}/apache-proxy-config-script.sh





