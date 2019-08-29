
#Requires -RunAsAdministrator

Param (
    [switch] $Wait,

    [Int]
    $Timeout = 35 #seconds
)

. ${env:ROOT_DIR}/scripts/Utils.ps1

function CheckTimeout([Diagnostics.Stopwatch] $timer) {
    if ($timer.Elapsed.TotalSeconds -gt $Timeout) {
        Throw "Importing cosmosDB cert timed out, try again by running  './Scripts/ImportCosmosDbCert.ps1'"
    }
}

$currDir = Get-Location
$volumePath =  "${env:COSMOS_DB_HOST_VOLUME_DIR}"
$importCertScriptPath = GetCertPath -GetImportScriptRatherThanCert
$certPath = GetCertPath

if ($Wait) {
    
    $timer = [Diagnostics.Stopwatch]::StartNew()

    "waiting for volume to finish being created... (may take a while)"
    while ( (-not (Test-Path $importCertScriptPath)) -or 
            (-not (Test-Path $certPath))) { 
                CheckTimeout($timer)
        
    }

    while ( (IsFileNotAccessible -FullFileName $importCertScriptPath) -or 
            (IsFileNotAccessible -FullFileName $certPath)) { 
                CheckTimeout($timer)
    }
    $timer.Stop()
}

"Importing cert"
Set-Location $volumePath
Invoke-Expression $importCertScriptPath
Set-Location $currDir

