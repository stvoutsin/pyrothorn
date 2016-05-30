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
# Update our path.
#[root@builder]

    # ** this should be in the container **
    source /etc/bashrc
    source "${HOME:?}/chain.properties"
    FIRETHORN_CODE=/projects/firethorn
    CLEARWING_CODE=/projects/clearwing

# -----------------------------------------------------
# Checkout a copy of our source code.
#[root@builder]




pushd "${FIRETHORN_CODE:?}"


    docker build \
        --tag "firethorn/ubuntu:14.04" \
        docker/ubuntu/14.04

    docker build \
        --tag "firethorn/python:3.4.2" \
        docker/python/3.4.2

    docker build \
        --tag "firethorn/pythonlibs" \
        docker/pythonlibs

popd

mkdir -p /projects/clearwing

#
# Clone our repository.
pushd "${CLEARWING_CODE:?}/"
	hg clone 'http://wfau.metagrid.co.uk/code/clearwing' .
        hg pull
	hg update -C ${clearwing_version:?}
popd


 source "${HOME:?}/firethorn.settings"
    pushd "${CLEARWING_CODE:?}"

	echo "# Building Webpy/Clearwing image"
	docker build \
	--tag firethorn/clearwing:${version:?} \
	src

    popd

exit
