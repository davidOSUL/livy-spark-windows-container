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
Get-Help .\StartContainers.ps1 -Detailed 
```
### CosmosDB Emulator
To start up a cosmosDB emulator container in addition to the spark/livy containers, open up a new powershell window <b>as an administrator</b>, cd into the repo folder, and execute the following command:
```
.\StartContainers.ps1 -CosmosDbEmulator <type> -ImportCosmosDbCert
```
Where \<type\> is one of: MSI, Cassandra, Gremlin.

To ONLY start up a cosmosDB emulator and not start spark/livy container do:

```
.\StartContainers.ps1 -CosmosDbEmulator <type> -DontStartSparkLivy -ImportCosmosDbCert
```
The -ImportCosmosDbCert flag is necessary to install the emulator's SSL certificate. If you prefer, you can run the command
without the flag (which doesn't require administrator access), and then later install the cert yourself by opening up a new powershell window <b>as an administrator</b>, cd into the repo folder, and executing the following command:
```
.\Scripts\ImportCosmosDbCert.ps1
```

### Changing default values for ports, etc.
Values for the ports used for the livy server, etc. can be changed in scripts/InitConfigValues.ps1
