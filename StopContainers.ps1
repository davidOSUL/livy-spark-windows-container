
Param (
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('AllContainers', 'CosmosDBOnly', 'SparkLivyOnly' )]
    [string]$Type,


    [Alias('v')]
    [switch]$RemoveVolumes
)

& ("${PSScriptRoot}/scripts/InitConfigValues.ps1")

. ${env:ROOT_DIR}/scripts/Utils.ps1


$command = (GetComposeCommand -Type $Type)
$command += " down"

if ($RemoveVolumes) {
    $command += " -v"
}

Invoke-Expression $command