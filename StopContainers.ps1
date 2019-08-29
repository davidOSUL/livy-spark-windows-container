
Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('AllContainers', 'CosmosDBOnly', 'SparkLivyOnly' )]
    [string]$Type,


    [Alias('v')]
    [switch]$RemoveVolumes
)

. ${env:ROOT_DIR}/scripts/Utils.ps1


$command = (GetComposeCommand -Type $Type)
$command += " down"

if ($RemoveVolumes) {
    $command += " -v"
}

Invoke-Expression $command