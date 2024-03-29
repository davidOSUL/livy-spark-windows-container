"Setting Configuration values"
#Livy/Spark configs
    $env:LIVY_SERVER_PORT = 8998
    $env:SPARK_WORKER_UI_PORT = 8082 
    $env:SPARK_MASTER_UI_PORT = 8080
    $env:SPARK_MASTER_PORT = 7077

#cosmosDB configs 
    $env:COSMOS_DB_HOST_PORT = 8081
    $env:CASSANDRA_ENDPOINT_HOST_PORT = 10350
    $env:GREMLIN_ENDPOINT_HOST_PORT = 8901
    $env:COSMOS_DB_HOST_VOLUME_DIR = "${env:LOCALAPPDATA}/CosmosDBEmulatorCert"
    $env:COSMOS_DB_MEM_LIMIT = "4GB"

#Docker configs
    #Right now this value isn't used because compose files don't support env variables in the "version" option
    $env:DOCKER_COMPOSE_VERSION= '2.4' #have to use version 2 to have mem_limit enabled. 
    $env:ROOT_DIR = (Get-Item ${PSScriptRoot}).Parent.FullName
    $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING_0 = "FAKE_ENV_VAR_0=true" 
    $env:COSMOSDB_CONTAINER_ENVIRONMENT_SETTING_1 = "FAKE_ENV_VAR_1=true"

