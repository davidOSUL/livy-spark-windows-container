# CosmosDB Emulator Dockerfile, Slight modification of file (see comments) found at https://github.com/Azure/azure-cosmos-db-emulator-docker
#For whatever reason, docker compose only works when I rebuild the image (that is, 
#pulling microsoft's cosmosdb emulator from docker-hub doesn't seem to work)

# Indicates that the windowsservercore image will be used as the base image.
#Changed From original 
FROM mcr.microsoft.com/windows/servercore:ltsc2019 

# Add the CosmosDB installer msi into the package
ADD https://aka.ms/cosmosdb-emulator c:\\CosmosDBEmulator\\AzureCosmosDB.Emulator.msi

# Copy misc scripts into the package
COPY package_scripts\\startemu.cmd c:\\CosmosDBEmulator\\startemu.cmd
COPY package_scripts\\getaddr.ps1 c:\\CosmosDBEmulator\\getaddr.ps1
COPY package_scripts\\exportcert.ps1 c:\\CosmosDBEmulator\\exportcert.ps1
COPY package_scripts\\importcert.ps1 c:\\CosmosDBEmulator\\importcert.ps1

# Install the MSI
RUN echo "Starting Installer"
RUN powershell.exe -Command $ErrorActionPreference = 'Stop'; \
   Start-Process 'msiexec.exe' -ArgumentList '/i','c:\CosmosDBEmulator\AzureCosmosDB.Emulator.msi','/qn' -Wait
RUN echo "Installer Done"

# Expose the required network ports
EXPOSE 8081
EXPOSE 8901
EXPOSE 8902
EXPOSE 10250
EXPOSE 10251
EXPOSE 10252
EXPOSE 10253
EXPOSE 10254
EXPOSE 10255
EXPOSE 10350

# Start the interactive shell
CMD [ "c:\\CosmosDBEmulator\\startemu.cmd" ]