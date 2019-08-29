# livy-spark-windows-container
Windows containers with Livy/Spark. 

Optionally can also use to start up a windows container with a cosmosDB emulator in addition to (or instead of) the containers with livy/spark.

# How to use

### Starting Up
1. Download the repo
2. Open up a new powershell window and cd into the downloaded repo
2. Execute the following command:
```
.\StartContainers.ps1 -RunInBackground
```
  This will start up three containers -- a spark worker, a spark master, and a livy server
  
  Once the containers are finished starting up, the livy server will be accesible at http://localhost:8998

### Stopping
To stop all containers execute the following command:
```
.\StopContainers.ps1 AllContainers
```

# Finer Details
### Script Options
To see how to use the script with more options do:
```
Get-Help .\StartContainers.ps1 -Detailed 
```
### CosmosDB Emulator
To start up a cosmosDB emulator container in addition to the spark/livy containers, open up a new powershell window <b>as an administrator</b>, cd into the repo folder, and execute the following command:
```
.\StartContainers.ps1 -CosmosDbEmulator -RunInBackground
```

To ONLY start up a cosmosDB emulator and not start spark/livy container do:

```
.\StartContainers.ps1 -CosmosDbEmulator -DontStartSparkLivy -RunInBackground
```

To start up an interactive shell in the cosmosDB emulator (with choice of ps/cmd) do:
```
.\Scripts\StartInteractiveCosmosDBShell.ps1 Powershell|CommandPrompt
```

The cosmosDB emulator can also be started up with a Gremlin and/or Cassandra endpoint using the "-CosmosDbEmulatorEndpoints" option. For example:

```
.\StartContainers.ps1 -CosmosDbEmulator -DontStartSparkLivy -RunInBackground -CosmosDbEmulatorEndpoints Gremlin
```



#### Emulator SSL Cert
- The script will automatically install the emulator's SSL certificate. 
  - If you prefer, you can run the command
with the -DontImportCosmosDbCert flag (which doesn't require administrator access), and then later install the cert yourself by opening up a new powershell window <b>as an administrator</b>, cd into the repo folder, and executing the following command:
  ```
  .\Scripts\ImportCosmosDbCert.ps1
  ```



### Changing default values for ports, etc.
Values for the ports used for the livy server, etc. can be changed in scripts/InitConfigValues.ps1

### Viewing Logs
To view docker logs (especially helpful when -RunInBackground is enabled) do:
```
.\Scripts\ViewLogs.ps1 <types>
```
for example to view the logs of the livy and spark-master containers do:
```
.\Scripts\ViewLogs.ps1  Livy,SparkMaster
```

# Problems
Here are some troubleshooting tips: 

NOTE: for all of these tips, if only the cosmosDB container is causing problems (or the import cert is), in addition to the flags that the troubleshooting tips say to use, make sure you also  run the script with the '-DontStartSparkLivy' flag, as it will save a lot of time.

1. First try to re-run the script.
    - You can also run the script without the -RunInBackground flag to see all the output from the docker logs as it runs.
2. Run:
    ```
    .\StopContainers AllContainers -RemoveVolumes
    ```
3. Re-run the script with the '-DockerPrune' flag
4. Re-run the script with the '-DockerPrune' and '-RebuildContainers' flags (this may take a while)
5. After trying everything above if you still are having issues do the following:
    1. Run:
        ```
        .\StopContainers AllContainers -RemoveVolumes
        ```
    2. If it exists, remove the directory "${env:LOCALAPPDATA}/CosmosDBEmulatorCert"
    3. Close all powershell windows and then open a new one and cd into the repo folder
    4. Run the script with the '-DockerPrune', '-RebuildContainers', and '-HardReset' options (this may take a while)
