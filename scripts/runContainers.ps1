
<#
.SYNOPSIS
    Set up spark livy server (with a master and worker) and optionally start a cosmosDB emulator as well.

.DESCRIPTION
    Start a spark livy server. Can also start a cosmosDB emulator container as part of the compose.
    To do so, pass in RunCosmosDBEmulator with a type (MSI, Cassandra, Gremlin) specifying whether this container
    should act (and have ports corresponding to) the MSI version of the emulator, with Cassandra endpoint API enabled,
    with Gremlin API enabled

.PARAMETER RunCosmosDbEmulator
    Add a cosmosDB emulator to the composed containers in addition to livy server

.PARAMETER RebuildContainers 
    Force Compose to rebuild all the containers

.PARAMETER RunInBackground 
    Run the containers in detached mode 

.PARAMETER DontStartSparkLivy
    Will not start the livy server/spark containers. If the RunCosmosDbEmulator option is provided
    will start the cosmosDB container only, otherwise will do nothing.
#>

Param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MSI','Cassandra', 'Gremlin')]
    [Alias('cosmosDB')]
    [string]$RunCosmosDbEmulator,

    [Alias('b', 'rebuild')]
    [switch]$RebuildContainers,

    [Alias('detach', '-d')]
    [switch]$RunInBackground,


    [switch]$DontStartSparkLivy
    
)

$script:sparkLivyComposeFile = " -f docker-compose.yml"
$script:cosmosDBComposeFile = ""
$script:RunningCosmosDBContainer = $PSBoundParameters.ContainsKey('RunCosmosDbEmulator')

if ($DontStartSparkLivy -And !$script:RunningCosmosDBContainer) {
    "Not starting any containers"
    exit 0
}

if ($script:RunningCosmosDBContainer) {

    $hostDir = "${env:LOCALAPPDATA}/azure-cosmosdb-emulator.hostd"
    mkdir $hostDir 2>$null 
    $script:cosmosDBComposeFile = " -f ./cosmosDBCompositions/docker-compose.cosmosDB_" + $RunCosmosDbEmulator + ".yml"
    switch($RunCosmosDbEmulator) {
        'MSI' {
            "Starting up docDB container with similar port settings to MSI version of emulator"
            $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING = ""
        }
        'Cassandra' {
            "Starting up docDB container with Cassandra endpoint API enabled on port 10350"
            $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING = "AZURE_COSMOS_EMULATOR_CASSANDRA_ENDPOINT=true"
        }
        'Gremlin' {
            "Starting up docDB container with Gremlin endpoint API enabled on port 8901"
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
$composeCommand += " up " + $extraParams 
"Executing Command: " + $composeCommand
"Starting up containers... (may take a while). When finished, the livy server will be accesible at localhost:8998"
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
Invoke-Expression $composeCommand


