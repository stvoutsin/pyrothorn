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

    echo "*** Initialising build script [build.sh] ***"
# -----------------------------------------------------
# Update our path.
#[root@builder]

    # ** this should be in the container **
    source /etc/bashrc

    yum install -y git

    echo "*** Checkout a copy of our source code. [build.sh] ***"
# -----------------------------------------------------
# Checkout a copy of our source code.
#[root@builder]

    #
    # Set the project path.
    if [ ! -e "${HOME:?}/firethorn.settings" ]
    then
        cat > "${HOME:?}/firethorn.settings" << EOF
FIRETHORN_CODE=/projects/firethorn
PROJECTS_CODE=/projects
PYROTHORN_CODE=/projects/pyrothorn
EOF
    fi
    

    #
    # Clone our repository.
    source "${HOME:?}/firethorn.settings"
    if [ ! -e "${FIRETHORN_CODE:?}" ]
    then
        pushd "$(dirname ${FIRETHORN_CODE:?})"

            hg clone 'http://wfau.metagrid.co.uk/code/firethorn'

        popd
    fi

    #
    # Pull and update from branch.
    source "${HOME:?}/firethorn.settings"
    pushd "${FIRETHORN_CODE:?}"

        hg pull
        hg update -C "${branch:?}"
        hg branch
    
    popd



    #
    # Clone our Pyrothorn repository.
    source "${HOME:?}/firethorn.settings"
    pushd "${PROJECTS_CODE:?}"

  	git clone https://github.com/stvoutsin/pyrothorn.git -b master
        git pull

    popd



    echo "*** Build our toolkit containers. [build.sh] ***"
# -----------------------------------------------------
# Build our toolkit containers.
#[root@builder]
    source "${HOME:?}/firethorn.settings"
      pushd "${FIRETHORN_CODE:?}"
  
        source 'bin/util.sh'
         dockerfiles "$(getversion)"
 
    popd

    export buildtag=${version}
    buildtag=${version}

    pushd "${FIRETHORN_CODE:?}"

        if [ $(docker images | grep -c '^firethorn/fedora') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Fedora image"
            docker build \
                --tag firethorn/fedora:${version}  \
                docker/fedora/24
        fi

        if [ $(docker images | grep -c '^firethorn/java') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Java image"
            docker build \
                --tag firethorn/java:${version} \
                docker/java/8
        fi

        if [ $(docker images | grep -c '^firethorn/tomcat') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Tomcat image"
            docker build \
                --tag firethorn/tomcat:${version} \
                docker/tomcat/8
        fi

        if [ $(docker images | grep -c '^firethorn/postgres') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Postgres image"
            docker build \
                --tag firethorn/postgres:${version} \
                docker/postgres/9
        fi

        if [ $(docker images | grep -c '^firethorn/builder') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Builder image"
            docker build \
                --tag firethorn/builder:${version} \
                docker/builder
        fi

        if [ $(docker images | grep -c '^firethorn/docker-proxy') -eq 0 ]
        then
            echo "# ------"
            echo "# Building docker-proxy image"
            docker build \
                --tag firethorn/docker-proxy:${version} \
                docker/docker-proxy
        fi

        if [ $(docker images | grep -c '^firethorn/sql-proxy') -eq 0 ]
        then
            echo "# ------"
            echo "# Building sql-proxy image"
            docker build \
                --tag firethorn/sql-proxy:${version} \
                docker/sql-proxy
        fi

        if [ $(docker images | grep -c '^firethorn/sql-tunnel') -eq 0 ]
        then
            echo "# ------"
            echo "# Building sql-tunnel image"
            docker build \
                --tag firethorn/sql-tunnel:${version} \
                docker/sql-tunnel
        fi

        if [ $(docker images | grep -c '^firethorn/ssh-client') -eq 0 ]
        then
            echo "# ------"
            echo "# Building ssh-client image"
            docker build \
                --tag firethorn/ssh-client:${version} \
                docker/ssh-client
        fi


    popd



    pushd "${PYROTHORN_CODE:?}"



   	if [ $(docker images | grep -c '^firethorn/pythonlibs') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Pythonlibs image"
            docker build \
                --tag firethorn/pythonlibs \
                containers/docker/pythonlibs
        fi

   	if [ $(docker images | grep -c '^firethorn/apache') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Apache image"
            docker build \
                --tag firethorn/apache:${version} \
                 containers/docker/apache
        fi


   	if [ $(docker images | grep -c '^firethorn/pyrosql') -eq 0 ]
        then
            echo "# ------"
            echo "# Building Pyrosql image"
            docker build \
                --tag firethorn/pyrosql \
                containers/docker/pyrosql
        fi


    popd


    echo "*** Build our webapp services. [build.sh] ***"
# -----------------------------------------------------
# Build our webapp services.
#[root@builder]

    #
    # Build our webapp services.
    source "${HOME:?}/firethorn.settings"
    pushd "${FIRETHORN_CODE:?}"

        mvn clean install

    popd


    echo "*** Build our webapp containers. [build.sh] ***"
# -----------------------------------------------------
# Build our webapp containers.
#[root@builder]

    source "${HOME:?}/firethorn.settings"
    pushd "${FIRETHORN_CODE:?}"

        pushd firethorn-ogsadai/webapp
            mvn -D "docker.host=unix:///var/run/docker.sock" docker:package
        popd
        
        pushd firethorn-webapp
            mvn -D "docker.host=unix:///var/run/docker.sock" docker:package
        popd

    popd


    echo "*** Build our tester container. [build.sh] ***"
# -----------------------------------------------------
# Build our tester container.
#[root@builder]

    source "${HOME:?}/firethorn.settings"
    pushd "${FIRETHORN_CODE:?}"

        source "bin/util.sh"

        if [ $(docker images | grep -c '^firethorn/tester') -eq 0 ]
        then
            echo "# ------"
            echo "# Building tester image"
            docker build \
               --tag firethorn/tester:$(getversion) \
               integration/tester
        fi
    popd

# -----------------------------------------------------
# Build our pyrothorn container.
#[root@builder]



    source "${HOME:?}/firethorn.settings"
    pushd "${PROJECTS_CODE:?}"
        

        if [ $(docker images | grep -c '^firethorn/pyrothorn') -eq 0 ]
        then
            echo "# ------"
            echo "# Building pyrothorn image"
            docker build \
                --tag firethorn/pyrothorn:${version:?} \
                pyrothorn

        fi
    popd


# -----------------------------------------------------
# Exit our builder.
#[root@builder]

    exit

# -----------------------------------------------------
