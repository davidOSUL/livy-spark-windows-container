# livy-spark-windows-container
Windows containers with Livy/Spark. 

Optionally can also use to start up a windows container with a cosmosDB emulator in addition to (or instead of) the containers with livy/spark.

# How to use
1. Download the repo
2. Open up a new powershell window and cd into the downloaded repo
2. Execute the following command:
```
.\StartContainers.ps1 -RunInBackground
```
  This will start up three containers -- a spark worker, a spark master, and a livy server
  
  Once the containers are finished starting up, the livy server will be accesible at http://localhost:8998
  
# Finer Details
### Script Options
To see how to use the script with more options do:
```
Get-Help .\ScriptContainers.ps1 -Detailed 
```
### CosmosDB Emulator
To start up a cosmosDB emulator container in addition to the spark/livy containers do:
```
.\StartContainers.ps1 -CosmosDbEmulator <type>
```
Where \<type\> is one of: MSI, Cassandra, Gremlin.

To ONLY start up a cosmosDB emulator and not start spark/livy container do:

```
.\StartContainers.ps1 -CosmosDbEmulator <type> -DontStartSparkLivy
```
Note that once you start up the cosmosDB emulator you will need to install the emulator's SSL certificate. 
To do this, open up a new powershell window <b>as an administrator</b>, cd into the repo folder, and execute the following command:
```
.\Scripts\ImportCosmosDbCert.ps1
```

### Changing default values for ports, etc.
Values for the ports used for the livy server, etc. can be changed in scripts/InitConfigValues.ps1
