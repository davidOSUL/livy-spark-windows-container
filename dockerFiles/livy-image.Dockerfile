########################################################################################
#Spark w/ Livy Dockerfiles. LIVY IMAGE
########################################################################################

#=================INITIAL SETUP============================================= 
    #Indicates that the base-image will be used as the base image.
        FROM base-image

    #Metadata indicating an image maintainer/description
        LABEL maintainer="t-daosul@microsoft.com"
        LABEL description="Used to build image with Livy server running on it"
#===========================================================================

#====================ENVIRONMENT VARIABLES====================================
    #Set Livy related Environment Variables
        ENV LIVY_HOME C:/apps/livy
        ENV LIVY_LOG $LIVY_HOME/logs
        #ENV LIVY_BUILD_VERSION 0.6.0
        
        ENV LIVY_DOWNLOAD_NAME livy-assembly-0.7.0-incubating-SNAPSHOT.zip
        ENV LIVY_FOLDER_NAME apache-livy-0.7.0-incubating-SNAPSHOT-bin
        #ENV LIVY_DOWNLOAD_NAME apache-livy-${LIVY_BUILD_VERSION}-incubating-bin.zip

        #Using my fork of livy because the apache version currently does not work on Windows OS
        ENV LIVY_DOWNLOAD_URL https://github.com/davidOSUL/incubator-livy/releases/download/v0.7-incubating-SNAPSHOT/${LIVY_DOWNLOAD_NAME}
        #ENV LIVY_DOWNLOAD_URL https://www-us.apache.org/dist/incubator/livy/${LIVY_BUILD_VERSION}-incubating/${LIVY_DOWNLOAD_NAME} 
#=================================================================================

#===================LIVY=================================================
    #Install Livy
        RUN wget ${env:LIVY_DOWNLOAD_URL} -UseBasicParsing -OutFile ${env:LIVY_DOWNLOAD_NAME} -PassThru 
        RUN Expand-Archive -Path ${env:LIVY_DOWNLOAD_NAME} -DestinationPath ${env:LIVY_HOME} ; \
            mv -Path ${env:LIVY_HOME}\${env:LIVY_FOLDER_NAME}\* -Destination ${env:LIVY_HOME} ; \
            rm ${env:LIVY_DOWNLOAD_NAME} ; \
            mkdir /apps/spark-modules ; \
            rm ${env:LIVY_HOME}/conf/*          
    
    #Copy Configuration files
        COPY ./configurations/ ${LIVY_HOME}/conf/
#========================================================================

VOLUME ["$LIVY_LOG"]

WORKDIR $LIVY_HOME