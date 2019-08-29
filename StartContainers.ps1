
<#
.SYNOPSIS
    Set up spark livy server (with a master and worker) and optionally start a cosmosDB emulator as well.

.DESCRIPTION
    Start a spark livy server. Can also start a cosmosDB emulator container as part of the compose.
    If neeeded, can open up Cassandra and/or Gremlin endpoints in the cosmosDB container.
    To do so, pass in CosmosDbEmulatorEndpoints flag with Cassandra and/or Gremlin

.PARAMETER CosmosDbEmulator
    Add a cosmosDB emulator to the composed containers in addition to livy server. 

.PARAMETER CosmosDbEmulatorEndpoints
    Add endpoints (Gremlin and/or cassandra) to the cosmosDB container

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

.PARAMETER DontImportCosmosDbCert
    Doesn't import the SSL cert for cosmos DB.
    Without this flag enabled,
    one must run the script as admin in order to work, and also have -RunInBackground enabled

.PARAMETER DockerPrune
    Runs "docker system prune" before doing anything else

.PARAMETER HardReset
    Before doing regular compose, rebuilds the containers that will be run with this script without any cache

.PARAMETER DontPullNewImages
    Don't pull new images from the remote repositiory (note that if the images do not exist, this will trigger a rebuild)

#>

[cmdletbinding(DefaultParameterSetName='NoCosmos')]
Param(
    [ValidateNotNullOrEmpty()]
    [Alias('cosmosDB', 'docDB')]
    [Parameter(ParameterSetName='Cosmos',Mandatory = $true )]
    [switch]$CosmosDbEmulator,

    [ValidateNotNullOrEmpty()]
    [ValidateSet('Cassandra', 'Gremlin')]
    [Alias('endpoints')]
    [Parameter(ParameterSetName='Cosmos')]
    [string[]]$CosmosDbEmulatorEndpoints,

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
    [switch]$DontImportCosmosDbCert,

    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$DockerPrune,

    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$HardReset,

    [Parameter(ParameterSetName='Cosmos')]
    [Parameter(ParameterSetName='NoCosmos')]
    [switch]$DontPullNewImages
    
)
$ImportCosmosDbCert = ($CosmosDBEmulator -and (-not $DontImportCosmosDbCert))
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin -And $ImportCosmosDbCert) {
    Throw "Must run script as an Admin in order to import cosmosDB SSL cert"
}

if ($ImportCosmosDbCert -And (-not $RunInBackground)) {
    Throw "Unable to import cosmosDB SSL cert unless -RunInBackgroundFlag is also used.
           Re-run the script with the -RunInBackground flag enabled.
           If for whatever reason you need to have RunInBackground disabled,
           then you must run the script with the -DontImportCosmosDbCert option,
           and then later you can run the ./scripts/ImportCosmosDbCert script yourself" #otherwise we will never get the chance to import the cert because docker will be active in the powershell window
}

if ((!$DockerPrune -or !$RebuildContainers) -and $HardReset) {
    Throw "HardReset option can only be used with both the DockerPrune and RebuildContainers options enabled"
}

if ($DockerPrune) {
    docker system prune
}

if (!$DontPullNewImages) {
    Invoke-Expression "docker pull -a davidosullivan/livy-spark-windows-container"
}

#Set up all the configuration values
& ("${PSScriptRoot}/scripts/InitConfigValues.ps1")

. ${env:ROOT_DIR}/scripts/Utils.ps1



$cosmosDBDuplicateErrorMessage = 'ERROR: Cannot create a cosmosDB container. A cosmosDB container is already running or a file in the volume is being used on the host machine. 
Make sure your cosmosDB containers are stopped! Try: "./StopContainers CosmosDBOnly -RemoveVolumes"'

if ($CosmosDbEmulator) {

    $hostDir = "${env:LOCALAPPDATA}/CosmosDBEmulatorCert"

    if ( (Test-Path $hostDir)) {
        $files = Get-ChildItem "$hostDir"
        foreach ($f in $files) {
            if (IsFileNotAccessible -FullFileName $f.FullName) {
                Throw $cosmosDBDuplicateErrorMessage
            }
        }
        try {
            "Attempting to remove hostdir"
            Remove-Item $hostDir -Recurse -Force -ErrorAction Stop
        } catch {
            Throw $cosmosDBDuplicateErrorMessage
        }
    }
   
    mkdir $hostDir 2>$null 
    "CosmosDB container will be accessible at ${env:COSMOS_DB_HOST_PORT}"
   
    #doing this rather than blank string to avoid docker warning
    $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING_0 = "FAKE_ENV_VAR_0=true" 
    $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING_1 = "FAKE_ENV_VAR_1=true"

    foreach($endpoint in $CosmosDbEmulatorEndpoints) {
        switch($endpoint) {
            'Cassandra' {
                "Cassandra endpoint API enabled on port ${env:CASSANDRA_ENDPOINT_HOST_PORT}"
                $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING_0 = "AZURE_COSMOS_EMULATOR_CASSANDRA_ENDPOINT=true"
            }
            'Gremlin' {
                "Gremlin endpoint API enabled on port ${env:GREMLIN_ENDPOINT_HOST_PORT}"
                $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING_1 = "AZURE_COSMOS_EMULATOR_GREMLIN_ENDPOINT=true"
            }
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

if ($CosmosDbEmulator) {
    if (!$DontStartSparkLivy) {
        $Type = 'AllContainers'
    } else {
        $Type = 'CosmosDBOnly'
    }
} else {
    $Type = 'SparkLivyOnly'
}

$composeCommand = GetComposeCommand -Type $Type

if ($HardReset) {
    Invoke-Expression ($composeCommand + " build --no-cache")
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

    if ($CosmosDbEmulator) {
        'To open up an interactive shell within the cosmosDB emulator use the script: "./scripts/StartInteractiveCosmosBShell.ps1"'
    }

    if (!$ImportCosmosDbCert) {
        "To import the cosmosDB SSL cert yourself do ./scripts/ImportCosmosDBCert.ps1"
    }

    'NOTE: If you encounter any issues try re-running the script.
    (if that still does not work try re-running the script with the -DockerPrune option)'
}

if (!$TestRun) {
    Invoke-Expression $composeCommand

    if (!$VerifyOnly -and $ImportCosmosDbCert) {
            Invoke-Expression "${env:ROOT_DIR}/scripts/ImportCosmosDbCert.ps1 -Wait"
    }
    
}



