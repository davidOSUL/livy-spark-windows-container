function GetComposeCommand(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]    
    [ValidateSet('AllContainers', 'CosmosDBOnly', 'SparkLivyOnly' )]
    [string]$Type) {
        $command = "docker-compose "
        switch($Type) {
            'AllContainers' {
                $command += "" 
            }
            'CosmosDBOnly' {
                $command += "-f ${env:ROOT_DIR}/dockercomposeFiles/docker-compose.cosmosDB.yml"
            }
            'SparkLivyOnly' {
                $command += "-f  ${env:ROOT_DIR}/dockercomposeFiles/docker-compose.yml"
            }
        }
        return $command

}

#https://stackoverflow.com/questions/9394629/how-to-check-if-file-is-being-used-by-another-process-powershell
function IsFileNotAccessible( [String] $FullFileName )
{
  [Boolean] $IsAccessible = $false

  try
  {
    Rename-Item $FullFileName $FullFileName -ErrorVariable LockError -ErrorAction Stop
    $IsAccessible = $true
  }
  catch
  {
    $IsAccessible = $false
  }
  return -not $IsAccessible
}

function GetCertPath([switch] $GetImportScriptRatherThanCert) {
    $volumePath =  "${env:COSMOS_DB_HOST_VOLUME_DIR}"
    $importCertScriptPath = $volumePath + "/importcert.ps1"
    $certPath = $volumePath + "/CosmosDBEmulatorCert.pfx"

    if ($getImportScriptRatherThanCert) {
        return $importCertScriptPath
    }
    else {
        return $certPath
    }
}