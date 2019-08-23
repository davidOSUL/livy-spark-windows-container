
<#
.SYNOPSIS
    Set up spark livy server (with a master and worker) and optionally start a cosmosDB emulator as well.

.DESCRIPTION
    Start a spark livy server. Can also start a cosmosDB emulator container as part of the compose.
    To do so, pass in CosmosDbEmulator with a type (MSI, Cassandra, Gremlin) specifying whether this container
    should act (and have ports corresponding to) the MSI version of the emulator, with Cassandra endpoint API enabled,
    with Gremlin API enabled

.PARAMETER CosmosDbEmulator
    Add a cosmosDB emulator to the composed containers in addition to livy server

.PARAMETER RebuildContainers 
    Force Compose to rebuild all the containers

.PARAMETER RunInBackground 
    Run the containers in detached mode 

.PARAMETER DontStartSparkLivy
    Will not start the livy server/spark containers. If the CosmosDbEmulator option is provided
    will start the cosmosDB container only, otherwise will do nothing.

.PARAMETER VerifyOnly
    Rather than starting any containers with docker-compose up will just verify the compose files with
    docker-compose config. 

.PARAMETER TestRun
    Does everything the script would normally do short of executing the compose command
    (that is, prints out what it would normally print out and sets config values)
#>

Param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MSI','Cassandra', 'Gremlin')]
    [Alias('cosmosDB', 'docDB')]
    [string]$CosmosDbEmulator,

    [Alias('b', 'rebuild')]
    [switch]$RebuildContainers,

    [Alias('detach', '-d')]
    [switch]$RunInBackground,

    [switch]$DontStartSparkLivy,

    [switch]$VerifyOnly,

    [switch]$TestRun
    
)


if ($DontStartSparkLivy -And !$script:RunningCosmosDBContainer) {
    "Not starting any containers"
    exit 0
}

#Set up all the configuration values
& ("${PSScriptRoot}/scripts/InitConfigValues.ps1")

$script:sparkLivyComposeFile = " -f  ${env:ROOT_DIR}/dockercomposeFiles/docker-compose.yml"
$script:cosmosDBComposeFile = ""
$script:RunningCosmosDBContainer = $PSBoundParameters.ContainsKey('CosmosDbEmulator')




if ($script:RunningCosmosDBContainer) {

    $hostDir = "${env:LOCALAPPDATA}/azure-cosmosdb-emulator.hostd"
    mkdir $hostDir 2>$null 
    $script:cosmosDBComposeFile = " -f ${env:ROOT_DIR}/dockercomposeFiles/docker-compose.cosmosDB.yml"
    "CosmosDB container accessible at ${env:COSMOS_DB_HOST_PORT}"
    switch($CosmosDbEmulator) {
        'MSI' {
            "Starting up docDB container with similar port settings to MSI version of emulator"
            $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING = ""
        }
        'Cassandra' {
            "Starting up docDB container with Cassandra endpoint API enabled on port ${env:CASSANDRA_ENDPOINT_HOST_PORT}"
            $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING = "AZURE_COSMOS_EMULATOR_CASSANDRA_ENDPOINT=true"
        }
        'Gremlin' {
            "Starting up docDB container with Gremlin endpoint API enabled on port ${env:GREMLIN_ENDPOINT_HOST_PORT}"
            $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING = "AZURE_COSMOS_EMULATOR_GREMLIN_ENDPOINT=true"
        }
    }
}

$extraParams = ""

if ($RunInBackground) {
    $extraParams += " --detach"
}
if ($RebuildContainers) {
    $extraParams += " --build"
}

$composeCommand = "docker-compose"

if (!$DontStartSparkLivy) {
    $composeCommand += $script:sparkLivyComposeFile
}

if ($script:RunningCosmosDBContainer) {
    $composeCommand +=  $script:cosmosDBComposeFile
}

#at this point we know !DontStartSparkLivy || RunningCosmosDBContainer (or else we would have exited at beggining) so can safely proceed with executing command
if ($VerifyOnly) {
    $composeCommand += " config"
} else {
    $composeCommand += " up " + $extraParams 
}
"Executing Command: " + $composeCommand

if (!$VerifyOnly) {
    "Starting up containers... (may take a while). When finished, the livy server will be accesible at localhost:${env:LIVY_SERVER_PORT}"
    'To stop all running containers do: "docker-compose down" To remove all volumes as well, append the "-v" flag'
    if (!$RunInBackground) {
        'You can also stop the containers with ctrl-c'
    }


    if ($RunInBackground) {
        'To see all the output from the containers do docker-compose logs'
        'To see output from just the livy-server, do "docker-compose logs livy"'
        if ($script:RunningCosmosDBContainer) {
            'To see output from the cosmos Db emulator, do "docker-compose logs cosmosdb"'
        }
    }

    if ($script:RunningCosmosDBContainer) {
        'To open up an interactive shell within the cosmosDB emulator do "docker-compose exec cosmosdb cmd"'
    }
    'NOTE: If you encounter any issues try "docker system prune" and re-running the script'
}

if (!$TestRun) {
    Invoke-Expression $composeCommand
}


