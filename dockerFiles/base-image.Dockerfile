########################################################################################
#Spark w/ Livy Dockerfiles. SPARK BASE IMAGE
########################################################################################

#=================INITIAL SETUP============================================= 
    #Indicates that the windowsservercore image will be used as the base image.
        FROM mcr.microsoft.com/windows/servercore:ltsc2019

    #Metadata indicating an image maintainer.
        LABEL description="Used as a base image with spark, scala, and java"
#===========================================================================

#====================ENVIRONMENT VARIABLES====================================
    #Set Spark related Environment Variables
        ENV SPARK_VERSION 2.4.3
        ENV SPARK_VERSION_STRING spark-$SPARK_VERSION-bin-hadoop2.7
        ENV SPARK_DOWNLOAD_URL https://www-us.apache.org/dist/spark/spark-$SPARK_VERSION/$SPARK_VERSION_STRING.tgz 
        ENV SPARK_FOLDER C:/apps/spark
        ENV SPARK_LOG $SPARK_FOLDER/logs
        ENV SPARK_HOME ${SPARK_FOLDER}/${SPARK_VERSION_STRING}
        ENV HADOOP_HOME ${SPARK_HOME}
        ENV SPARK_BIN ${SPARK_HOME}/bin

    #Set winutils related environment variables (NOTE: should be the same hadoop version as SPARK_VERSION_STRING)====
        ENV WINUTILS_DOWNLOAD_URL https://github.com/steveloughran/winutils/raw/master/hadoop-2.7.1/bin/winutils.exe

    #Set Java related Environment Variables
        ENV JAVA8_URL http://javadl.oracle.com/webapps/download/AutoDL?BundleId=210185
        ENV JAVA_DOWNLOAD_NAME jre-8u91-windows-x64.exe
        ENV JAVA_HOME 'C:\Java\jre1.8.0_91'
    
    #Set scala related Environment Variables
        ENV SCALA_VERSION 2.13.0
        ENV SCALA_MSI_NAME scala-${SCALA_VERSION}.msi
        ENV SCALA_DOWNLOAD_URL https://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_MSI_NAME}
        ENV SCALA_HOME 'C:\scala'
        
#===========================================================================

#==========================SHELLL SETUP=====================================
   #Set up Shell
        SHELL ["powershell", "-command", "$ErrorActionPreference = 'Stop';"]
#===========================================================================

#=========================JAVA=============================================
    #Install Java 8
        RUN wget ${env:JAVA8_URL} -UseBasicParsing -OutFile ${env:JAVA_DOWNLOAD_NAME} -PassThru
        RUN start-process -filepath C:\${env:JAVA_DOWNLOAD_NAME} -passthru -wait -argumentlist "/s,INSTALLDIR=${env:JAVA_HOME},/L,install64.log"
        RUN rm ${env:JAVA_DOWNLOAD_NAME}
    
    #Append to PATH
        RUN setx /M PATH $( ${env:PATH} + ';'+ ${env:JAVA_HOME} + '\bin' )
#==========================================================================

#=======================SPARK===============================================
    #Install Spark
        RUN wget ${env:SPARK_DOWNLOAD_URL} -UseBasicParsing -OutFile sparkFile.tgz -PassThru
        RUN mkdir ${env:SPARK_FOLDER} ; \
            mkdir tmp; \
            tar xvf sparkFile.tgz -C tmp ; \
            cp -Recurse -Force tmp/* ${env:SPARK_FOLDER} ; \
            rm -Recurse -Force -- tmp ; \
            rm sparkFile.tgz ; 
    
    #Set up environment variables to finish spark install 
        RUN setx /M PATH $( ${env:PATH} + ';'+ ${env:SPARK_BIN} )
#==========================================================================

#====================WINUTILS============================================
    #Install winutils (needed for spark to run on windows)
        RUN wget ${env:WINUTILS_DOWNLOAD_URL} -UseBasicParsing -OutFile "${env:SPARK_BIN}/winutils.exe" -PassThru 
#========================================================================

#==================SCALA================================================
    #Install Scala 
        RUN echo ${env:SCALA_DOWNLOAD_URL}
        RUN wget ${env:SCALA_DOWNLOAD_URL} -UseBasicParsing -OutFile ${env:SCALA_MSI_NAME} -PassThru 
        RUN mkdir ${env:SCALA_HOME} ; \
            start-process -filepath C:\${env:SCALA_MSI_NAME} -passthru -wait -argumentlist "/quiet,INSTALLDIR=${env:SCALA_HOME}" ; \
            rm ${env:SCALA_MSI_NAME} ;
            
     #Set up environment variables to finish scala install 
        RUN setx /M PATH $( ${env:PATH} + ';'+ ${env:SCALA_HOME} + '\bin' )
#=======================================================================


VOLUME ["$SPARK_LOG"]

WORKDIR $SPARK_FOLDER

CMD ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]