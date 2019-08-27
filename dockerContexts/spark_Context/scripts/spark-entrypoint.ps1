Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Worker','Master')]
    [string]$Type
)

Set-Location ${env:SPARK_HOME}

    If ($Type -eq 'Worker') 
    {
        .\bin\spark-class org.apache.spark.deploy.worker.Worker --webui-port ${env:SPARK_WORKER_UI_PORT} spark://master:${env:SPARK_MASTER_PORT}
    } 
    elseif ($Type -eq 'Master') {
        .\bin\spark-class org.apache.spark.deploy.master.Master --port ${env:SPARK_MASTER_PORT} --webui-port ${env:SPARK_MASTER_UI_PORT}
    }
