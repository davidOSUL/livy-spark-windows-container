Param (
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Livy', 'CosmosDB', 'SparkWorker', 'SparkMaster' )]
    [string[]]$Types
)

. ${env:ROOT_DIR}/scripts/Utils.ps1


foreach ($t in $Types) {
    switch ($t) {
        {@('Livy', 'SparkWorker', 'SparkMaster') -contains $_}  {
            $ContainerType = 'SparkLivyOnly'
        }
        'CosmosDB' {
            $ContainerType = 'CosmosDBOnly'
        }
    }
    $command = (GetComposeCommand -Type $ContainerType)
    $command += " logs"
    switch ($t) {
        'Livy'  {
            $serviceName = 'livy'
        }
        'CosmosDB'  {
            $serviceName = 'cosmosdb'
        }
        'SparkWorker'  {
            $serviceName = 'worker'
        }
        'SparkMaster'  {
            $serviceName = 'master'
        }
    }
    $command += " " + $serviceName
    Invoke-Expression $command
}

