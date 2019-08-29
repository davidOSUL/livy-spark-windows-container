Param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Powershell','CommandPrompt')]
    [string]$Type
)

$command = "docker exec -it cosmosDB "

switch($Type) {
    'Powershell' {
        $command += 'powershell'
    }
    'CommandPrompt' {
        $command += 'cmd'
    }
}

Invoke-Expression $command