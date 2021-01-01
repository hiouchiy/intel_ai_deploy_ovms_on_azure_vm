# How to automatically deploy OpenVINO™　Model Server on Azure VM

## Setup enviroment
```Bash
docker pull mcr.microsoft.com/azure-cli:latest
docker run -it mcr.microsoft.com/azure-cli:latest
```

Continue inside the container from this command. 

```Bash
git clone https://github.com/hiouchiy/intel_ai_deploy_ovms_on_azure_vm.git
cd intel_ai_deploy_ovms_on_azure_vm
```

## Configure 'deploy_config.csv' file (CSV format, no header)
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
### Parameters
-1 Config file path
-1 Specific name of resource group to be created

## Delete Resource Group

Use Azure CLI directly as below.

```Bash
az group delete --name ResourceGroupName --y
```
