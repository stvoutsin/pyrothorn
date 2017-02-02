# Pyrothorn
Pyrothorn is a testing suite for the Firethorn project (http://wfau.metagrid.co.uk/code/firethorn).
Consists of pyrothorn source code that handles querying through Firethorn, SQLServer, MySQL & TAP, and scripts to setup and run Docker test chain for all different test cases, or deployment.


# Usage Example:  

```
run.sh testname branch version additional_param
```


**Available Tests:**
 
* 01 - Integration test, Query 1000 rows in Firethorn vs Direct SQL Server connection & compare results
* 02 - Full ATLASDR1 query test, query 1000 rows in Firethorn vs Direct SQL Server connection & compare results
* 03 - Run same comparison test in historical queries for database stored in 'secret.store'
* 04 - Query loop test, Start a continuous loop that will send queries through Firethorn. Used to test memory leaks
* 05 - JSON Integration test, Query 1000 rows in Firethorn and check if rows match expected number
* 06 - Tap test, Send 1000 rows through the given TAP service, and compare results with Direct SQL Server query
* 07 - Perform 06 test, but also run a taplint validation test
* 08 - Build a TAP Service for a given catalogue. (Uses secret.store database credentials)
* 09 - Build a Clearwing (webpy interface) container
* 10 - Create Firethorn chain
* 11 - Run dual MySQL/SQLServer test. Compare queries results between two
* 12 - Run DQP tests
* 13 - Build Apache proxy container



The research leading to these results has received funding from the European Community's Seventh Framework Programme (FP7-SPACE-2013-1) under grant agreement n°606740.

