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
1. Function's name in Azure Functions
1. Model name on OpenVINO Model Server
1. Azure VM's name
1. Name of environemnt variable for IP address
1. Name of environemnt variable for port number
1. Port number
1. The path of Model file on Azure Storage
1. ARM Parameter file path

## Start deployment
First, login to Azure.
```Bash
az login
```

If you want to login without web browser, follow the instrunctions below to setup service principle. Refer [this site](https://tech.nsw-cloud.jp/2018/12/28/%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E4%B8%80%E7%99%BA%E3%81%A7azure-cli%E3%81%AB%E3%82%B5%E3%82%A4%E3%83%B3%E3%82%A4%E3%83%B3/) for the details.
```Bash
az ad sp create-for-rbac --name ${DisplayName} --create-cert
``` 

Below result will be output.
```Bash
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "${DisplayName}",
  "fileWithCertAndPrivateKey": "/home/user/xxxxxxxxxxx.pem",
  "name": "http://${DisplayName}",
  "password": null,
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

After that, you can login with below command.
```Bash
az login --service-principal \
         --username ${appId} \
         --tenant ${tenantId} \
         --password ${fileWithCertAndPrivateKey} \
```

Finally, run the command below.
```Bash
source ./deploy_vm.sh deploy_config.csv ResourceGroupName AzureStorageConnectionString
```

### Parameters
1. Config file path
1. Specific name of resource group to be created

## Delete Resource Group

Use Azure CLI directly as below.

```Bash
az group delete --name ResourceGroupName --y
```
