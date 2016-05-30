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

  echo "*** Initialising build scripts [setup.sh] ***"

  echo "*** Installing tools [setup.sh] ***"
   
# -----------------------------------------
# Install admin tools.
#
    yum -y install htop
    yum -y install pwgen
    
# -----------------------------------------------------
# Install and start the HAVEGE entropy generator.
# http://redmine.roe.ac.uk/issues/828
# http://blog-ftweedal.rhcloud.com/2014/05/more-entropy-with-haveged/
# http://stackoverflow.com/questions/26021181/not-enough-entropy-to-support-dev-random-in-docker-containers-running-in-boot2d/
#
    yum install -y haveged
    systemctl start haveged.service

    echo "*** Installing & starting docker [setup.sh] ***"
# -----------------------------------------------------
# Install and start Docker.
#
    yum install -y https://kojipkgs.fedoraproject.org//packages/docker-io/1.6.2/3.gitc3ca5bb.fc21/x86_64/docker-io-1.6.2-3.gitc3ca5bb.fc21.x86_64.rpm
	

    systemctl enable docker.service
    systemctl start  docker.service
    systemctl status docker.service


# -----------------------------------------------------
# Remove existing docker containers and images
#

    # Delete all containers
    docker rm -f -v $(docker ps -a -q) 
    # Delete all images
    docker rmi -f $(docker images -q)

    echo "*** Creating projects & cache directories [setup.sh] ***"
# -----------------------------------------------------
# Create our projects directory.
#
    if [ ! -e /var/local/projects ]
    then
        mkdir -p /var/local/projects
        chgrp -R users /var/local/projects
        chmod -R g+rwx /var/local/projects
    fi

# -----------------------------------------------------
# Create our cache directory.
#

    if [ ! -e /var/local/cache ]
    then
        mkdir -p /var/local/cache
        chgrp -R users /var/local/cache
        chmod -R g+rwx /var/local/cache
    fi

# -----------------------------------------------------
# Allow access to Docker containers.
#
    chcon -t svirt_sandbox_file_t "/var/local/projects" 
    chcon -t svirt_sandbox_file_t "/var/local/cache" 

# -----------------------------------------------------
# Install the selinux-dockersock SELinux policy.
# https://github.com/dpw/selinux-dockersock
#
    # Test if present
    # semodule -l | grep dockersock

    yum install -y git
    yum install -y make
    yum install -y checkpolicy
    yum install -y policycoreutils policycoreutils-python
    
    pushd /var/local/projects

        git clone https://github.com/dpw/selinux-dockersock

        pushd selinux-dockersock

            make dockersock.pp

            semodule -i dockersock.pp

        popd
    popd

    chmod a+r "${HOME:?}/setup/build.sh" 
    chcon -t svirt_sandbox_file_t "${HOME:?}/setup/build.sh" 
 
    touch ${HOME:?}/chain.properties
    chmod a+r "${HOME:?}/chain.properties"
    chcon -t svirt_sandbox_file_t "${HOME:?}/chain.properties"

    echo "*** Creating docker chain properties file [setup.sh] ***"

    cat > ${HOME:?}/chain.properties << EOF

    version=${version:?}

    metaname=bethany
    username=patricia
    dataname=elayne
    ogsaname=jarmila
    firename=gillian
    pyroname=pyrothorn
    storedqueriesname=maria
    pyrosqlname=mikaela

    metalink=albert
    userlink=edward
    datalink=sebastien
    ogsalink=timothy
    firelink=peter
    storedquerieslink=john
    pyrosqllink=mike

    metatype=mssql
    metadata=$(secret 'firethorn.meta.data')
    metauser=$(secret 'firethorn.meta.user')
    metapass=$(secret 'firethorn.meta.pass')
    metaport=1433
    metadriver=net.sourceforge.jtds.jdbc.Driver

    usertype=mssql
    userhost=$(secret 'firethorn.user.host')
    userdata=$(secret 'firethorn.user.data')
    useruser=$(secret 'firethorn.user.user')
    userpass=$(secret 'firethorn.user.pass')
    userdriver=net.sourceforge.jtds.jdbc.Driver

    datatype=mssql
    datahost=$(secret 'firethorn.data.host')
    datadata=$(secret 'firethorn.data.data')
    datauser=$(secret 'firethorn.data.user')
    datapass=$(secret 'firethorn.data.pass')
    datadriver=net.sourceforge.jtds.jdbc.Driver
    dataport=1433

    pyrosqlport=3306
    
    storedqueriesport=1433
    storedquerieshost=$(secret 'pyrothorn.storedqueries.host')
    storedqueriesdata=$(secret 'pyrothorn.storedqueries.data')
    storedqueriesuser=$(secret 'pyrothorn.storedqueries.user')
    storedqueriespass=$(secret 'pyrothorn.storedqueries.pass')
    
    testrundatabase=$(secret 'firethorn.data.data')
    testrun_ogsadai_resource=$(secret 'firethorn.data.data')

    tunneluser=$(secret 'ssh.tunnel.user')
    tunnelhost=$(secret 'ssh.tunnel.host')

    defaultrows=$(secret 'defaultrows')
    absoluterows=$(secret 'absoluterows')


    clearwing_host=$(secret 'clearwing_host')
    clearwing_port=$(secret 'clearwing_port')
    clearwing_host_alias=$(secret 'clearwing_host_alias')
    clearwing_tap_service=$(secret 'clearwing_tap_service')
    clearwing_tap_service_title=$(secret 'clearwing_tap_service_title')
    default_community=$(secret 'default_community')
    private_survey=$(secret 'private_survey')
    private_survey_vphas=$(secret 'private_survey_vphas')
    authentication_database=$(secret 'authentication_database')
    authentication_table=$(secret 'authentication_table')
    authentication_database_user=$(secret 'authentication_database_user')
    authentication_database_password=$(secret 'authentication_database_password')
    query_store_database_server=$(secret 'query_store_database_server')
    query_store_database=$(secret 'query_store_database')
    query_store_table=$(secret 'query_store_table')
    survey_database=$(secret 'survey_database')
    survey_database_user=$(secret 'survey_database_user')
    survey_database_password=$(secret 'survey_database_password')
    survey_database_server=$(secret 'survey_database_server')
    vphasdbuser=$(secret 'vphasdbuser')
    vphasdbpasswd=$(secret 'vphasdbpasswd')
    vphasdbserver=$(secret 'vphasdbserver')
    firethorn_tap_base=$(secret 'firethorn_tap_base')

EOF


    source ${HOME:?}/chain.properties


    echo "*** Running build container [setup.sh] ***"
# -----------------------------------------------------
# Run our build container.
#
    docker run \
        -it \
        --name builder \
        --env "branch=${branch:?}" \
        --env "version=${version:?}" \
        --volume /var/local/cache:/cache \
        --volume /var/local/projects:/projects \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        --volume ${HOME:?}/setup/build.sh:/build.sh \
        firethorn/builder:1 \
        bash ./build.sh
