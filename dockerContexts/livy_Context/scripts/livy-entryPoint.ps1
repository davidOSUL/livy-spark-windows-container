Set-Location ${env:LIVY_HOME}

#this is necessary because livy configuration files don't support environment variables directly
$confFiles = Get-ChildItem "conf/"
$environmentVariables = Get-ChildItem env:*
"Replacing environment variables in conf files"
foreach ($f in $confFiles){
    foreach ($var in $environmentVariables) {
        $variableName = '${env:' + $var.NAME + '}'
        (Get-Content $f.FullName).replace($variableName, $var.Value) | Set-Content $f.FullName
    }
}

java -cp "./jars/*;./conf;" org.apache.livy.server.LivyServer