# How to automatically deploy OpenVINO™　Model Server on Azure VM

## Setup enviroment
```Bash
docker pull mcr.microsoft.com/azure-cli:latest
docker run -it mcr.microsoft.com/azure-cli:latest
```

## Configuration file (CSV format)
-1 Function's name in Azure Functions
-1 Model name on OpenVINO Model Server
-1 Azure VM's name
-1 Name of environemnt variable for IP address
-1 Name of environemnt variable for port number
-1 Port number
-1 The path of Model file on Azure Storage
-1 ARM Parameter file path

## Run Command
```Bash
source ./deploy_vm.sh deploy_config.csv ResourceGroupName
```

## Delete Resource Group
```Bash
az group delete --name ResourceGroupName --y
```
