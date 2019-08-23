Set-Location ${env:LIVY_HOME}
java -cp "./jars/*;./conf;" org.apache.livy.server.LivyServer