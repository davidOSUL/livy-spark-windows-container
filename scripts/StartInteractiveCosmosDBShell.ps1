Param (
    [Parameter(Position=0, Mandatory=$true)]
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
"To exit do: control-P control-Q"
Invoke-Expression $command