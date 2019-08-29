
<#
.SYNOPSIS
    Set up spark livy server (with a master and worker) and optionally start a cosmosDB emulator as well.

.DESCRIPTION
    Start a spark livy server. Can also start a cosmosDB emulator container as part of the compose.
    To do so, pass in CosmosDbEmulator with a type (MSI, Cassandra, Gremlin) specifying whether this container
    should act (and have ports corresponding to) the MSI version of the emulator, with Cassandra endpoint API enabled,
    with Gremlin API enabled

.PARAMETER CosmosDbEmulator
    Add a cosmosDB emulator to the composed containers in addition to livy server. 

.PARAMETER RebuildContainers 
    Force Compose to rebuild all the containers

.PARAMETER RunInBackground 
    Run the containers in detached mode 

.PARAMETER DontStartSparkLivy
    Will not start the livy server/spark containers (will only start cosmosDB)

.PARAMETER VerifyOnly
    Rather than starting any containers with docker-compose up will just verify the compose files with
    docker-compose config. 

.PARAMETER TestRun
    Does everything the script would normally do short of executing the compose command
    (that is, prints out what it would normally print out and sets config values)

.PARAMETER ImportCosmosDbCert
    Imports the SSL cert for cosmos DB. Requires running script as admin in order to work, and also reequires -RunInBackground enabled

.PARAMETER DockerPrune
    Runs "docker system prune" before doing anything else

#>

[cmdletbinding(DefaultParameterSetName='NoCosmos')]
Param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MSI','Cassandra', 'Gremlin')]
    [Alias('cosmosDB', 'docDB')]
    [Parameter(ParameterSetName='Cosmos',Mandatory = $true )]
    [string]$CosmosDbEmulator,

    [Alias('b', 'rebuild')]
    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$RebuildContainers,

    [Alias('detach', '-d')]
    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$RunInBackground,

    [Parameter(ParameterSetName='Cosmos')]
    [switch]$DontStartSparkLivy,

    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$VerifyOnly,

    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$TestRun,

    [Parameter(ParameterSetName='Cosmos')]
    [switch]$ImportCosmosDbCert,

    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$DockerPrune
    
)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin -And $ImportCosmosDbCert) {
    Throw "Must run script as an Admin in order to import cert"
}

if ($ImportCosmosDbCert -And (-not $RunInBackground)) {
    Throw "Cannot use -ImportCosmosDbCert flag unless -RunInBackgroundFlag is also used" #otherwise we will never get the chance to import the cert because docker will be active in the powershell window
}



if ($DockerPrune) {
    docker system prune
}

#Set up all the configuration values
& ("${PSScriptRoot}/scripts/InitConfigValues.ps1")

$script:sparkLivyComposeFile = " -f  ${env:ROOT_DIR}/dockercomposeFiles/docker-compose.yml"
$script:cosmosDBComposeFile = ""
$script:RunningCosmosDBContainer = $PSBoundParameters.ContainsKey('CosmosDbEmulator')

. ${env:ROOT_DIR}/scripts/Utils.ps1

$cosmosDBDuplicateErrorMessage = 'ERROR: Cannot create a cosmosDB container. A cosmosDB container is already running or a file in the volume is being used on the host machine. 
Make sure your cosmosDB containers are stopped! Try: "./StopContainers -Type CosmosDBOnly -RemoveVolumes"'

if ($script:RunningCosmosDBContainer) {

    $hostDir = "${env:LOCALAPPDATA}/CosmosDBEmulatorCert"
    if (Test-Path $hostDir) {
        "Attempting to remove cosmosDB volume"
        try {
            Remove-Item $hostDir -Recurse -Force -ErrorAction Stop
        } catch {
            Throw $cosmosDBDuplicateErrorMessage
        }
    }
    mkdir $hostDir 2>$null 
    $script:cosmosDBComposeFile = " -f ${env:ROOT_DIR}/dockercomposeFiles/docker-compose.cosmosDB.yml"
    "CosmosDB container will be accessible at ${env:COSMOS_DB_HOST_PORT}"
    switch($CosmosDbEmulator) {
        'MSI' {
            "Starting up docDB container with similar port settings to MSI version of emulator"
            $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING = "FAKE_ENV_VAR=true" #doing this rather than blank string to avoid docker warning
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

if ($VerifyOnly) {
    $composeCommand += " config"
} else {
    $composeCommand += " up " + $extraParams + " --force-recreate"
}
"Executing Command: " + $composeCommand

if (!$VerifyOnly) {
    "Starting up containers... (may take a while)."

    if (!$DontStartSparkLivy) {
        "When finished, the livy server will be accesible at localhost:${env:LIVY_SERVER_PORT}"
    }

    'To stop all containers started with this script do: "./StopContainers AllContainers" To remove all volumes as well, append the "-RemoveVolumes" flag'
    if (!$RunInBackground) {
        'You can also stop the containers with ctrl-c'
    }


    if ($RunInBackground) {
       'To see the docker logs use the "./scripts/ViewLogs.ps1" script'
    }

    if ($script:RunningCosmosDBContainer) {
        'To open up an interactive shell within the cosmosDB emulator use the script: "./scripts/StartInteractiveCosmosBShell.ps1"'
    }
    'NOTE: If you encounter any issues try re-running the script.
    If that still does not work try re-running the script with the -DockerPrune option)'
}

if (!$TestRun) {
    Invoke-Expression $composeCommand
}

if ($ImportCosmosDbCert) {
    Invoke-Expression "${env:ROOT_DIR}/scripts/ImportCosmosDbCert.ps1 -Wait"
}

