# Firethorn-JSON-test Documentattion

The following describes the set of steps required  to run the Pyrothorn JSON query test (test14)
The test takes a JSON file of queries, and resources, creates a Firethorn workspace with the given resources and runs through the list of queries.

# Login to the the VM

ssh Delild


# Install git

yum install git


# Clone repository

git clone https://github.com/stvoutsin/pyrothorn.git

cwd=$(pwd)


# Create our Configuration (Secrets) file

secretfile=${HOME:?}/secrets


cat > "${secretfile:?}" << 'EOF'


firethorn.meta.data=

firethorn.meta.user=

firethorn.meta.pass=

firethorn.meta.host=


firethorn.user.data=

firethorn.user.user=

firethorn.user.pass=

firethorn.user.host=

firethorn.data.data=

firethorn.data.user=

firethorn.data.pass=

firethorn.data.host=

pyrothorn.storedqueries.data=

pyrothorn.storedqueries.host=

pyrothorn.storedqueries.user=

pyrothorn.storedqueries.pass=

ssh.tunnel.user=

ssh.tunnel.host=


absoluterows=10000

defaultrows=10000


EOF



  
# Create our secret function.


    secret()
        {
        key=${1:?}
	sed -n "s/^ *$key *= *//p" ${secretfile}
        }



# Set permissions to scripts

   chmod 755 ${cwd:?}/pyrothorn/scripts





# Create your JSON file 

Create your own queries.json file with json list of queries 

nano /root/queries.json

...

{

	"resources": [
        {
                "type": "local",
                "name": "TWOMASS",
                "metadoc": "testing/metadocs/TWOMASS_TablesSchema.xml"

        },
        {
                "type": "ivoa",
                "url": "http://gea.esac.esa.int/tap-server/tap",
                "metadoc": "testing/metadocs/gaia-tableset.xml",
                "alias": "GAIA TAP Service",
                "name": "gaiadr1",
                "schema": "gaiadr1"
        }],
	"queries": [

		
                {
			"query" : "SELECT TOP 10 * FROM Filter",
                        "rows": 10
                },
                {
			"query" : "SELECT COUNT(*) FROM Filter",
                        "rows": 1
                },
                {
                        "query" : "SELECT COUNT(*) FROM gaiadr1.gaia_source",
                        "rows": 1
                }

              

	]

}

...



# Set the version of Firethorn and hg changeset

newversion=2.1.5
hgchangeset=4b5097b7d4d9

# Run JSON query test
source run.sh 14  default  ${newversion:?} /root/queries.json


# Observing Results

To observe results, you can either tail the logfile

tail -f -n 1000 /var/logs/pyrothorn/logfile.txt

..

Or connect to the MySQL results database container

    docker exec -it mikaela bash
    mysql
    ..
    mysql> USE pyrothorn_testing;
    mysql> SELECT * from queries;
