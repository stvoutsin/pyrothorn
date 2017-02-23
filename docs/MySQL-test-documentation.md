MySQL-SQLServer Test Documentattion

The following describes the set of steps required  to run the Pyrothorn MySQL-SQLServer test (test11.sh) that runs a list of queries
through two versions of the same data in an SQL Server, and a MySQL database, comparing the rows returned in each and logging
the runtime for each.

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

firethorn.data.data=sqlserver_database ## The database name of the SQL Server DB you are using
firethorn.data.user=sqlserver_username ## The SQL Server username you are using
firethorn.data.pass=sqlserver_password ## The SQL Server password you are using
firethorn.data.host=sqlserver_host ## The SQL Server host


ssh.tunnel.user=user ## Username if you are setting up an ssh tunnel for the SQL Server connection
ssh.tunnel.host=host ## Host for which to setup the ssh tunnel for the SQL Server connection

defaultrows=max_rows_returned ## Max rows returned

mysql_test_dbserver=mysql_server_host
mysql_test_dbserver_username=mysql_server_username ## The MySQL Server username
mysql_test_dbserver_password=mysql_server_password ## The MySQL Server password
mysql_test_dbserver_port=mysql_server_port ## The MySQL Server port
mysql_test_database=mysql_server_database ## The MySQL Database
mysql_test_driver=mysql_server_driver (MySQL) 



EOF


  
# Create our secret function.


    secret()
        {
        key=${1:?}
	sed -n "s/^ *$key *= *//p" ${secretfile}
        }



# Set permissions to scripts

   chmod 755 ${cwd:?}/pyrothorn/scripts




# Create your own mysql-sqlserver.json file 

Create JSON list of queries under ${cwd:?}/pyrothorn/testing/query_logs/mysql-sqlserver.json

Note: "rows" element not required for this test


# Set the version of Firethorn (Latest:2.1.4)

newversion=2.1.4
   


# Run MySQL - SQLServer test

CD to our pyrothorn directory and run the test.

   cd ${cwd:?}/pyrothorn/scripts

   source run.sh 11 default  ${newversion:?}


# Observing Results

To observe results, you can either tail the logfile
    tail -f -n 1000 /var/logs/pyrothorn/logfile.txt

Or connect to the MySQL results database container
The results are stored in a database named pyrothorn_testing, in a table named queries;

    docker exec -it mikaela bash
    mysql
    ..
    mysql> USE pyrothorn_testing;
    mysql> DESCRIBE queries;
    mysql> SELECT * from queries;

