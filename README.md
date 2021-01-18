# How to deploy OpenVINO™ Model Server automatically onto Azure VM for OVaaS 

This instruction shows how to launch Azure VM and deploy OpenVINO™ Model Server and specific model (IR format) on that from Azure CLI. With this instructions and scripts, We can newly deploy and delete Azure VM and Model server at the timing whenever we want. 

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

## Setup a configuration file (JSON format)
### Multiple model servers on single VM
You can deploy multiple model servers on single VM with configuration below. This configuraiton can save cost due to least number of VM but is basically better for test or develop use.
```JSON
[
    {
        "vm_name": "modelservervm",
        "vm_size": "Standard_D2s_v4",
        "models":[
            {
                "function_name": "humanpose",
                "model_name": "human-pose-estimation",
                "env_name_ip": "HUMANPOSE_IPADDRESS",
                "env_name_port": "HUMAN_POSE_PORT",
                "port_number": 9000,
                "model_path_on_azure_storage": "az://ovms/intel/human-pose-estimation-0001/FP16-INT8"
            },
            {
                "function_name": "handwritten",
                "model_name": "handwritten-japanese-recognition",
                "env_name_ip": "HANDWRITTEN_IPADDRESS",
                "env_name_port": "HAND_WRITTEN_PORT",
                "port_number": 9001,
                "model_path_on_azure_storage": "az://ovms/intel/handwritten-japanese-recognition-0001/FP16-INT8"
            },
            {
                "function_name": "colorization",
                "model_name": "colorization",
                "env_name_ip": "COLORIZATION_IPADDRESS",
                "env_name_port": "COLORIZATION_PORT",
                "port_number": 9002,
                "model_path_on_azure_storage": "az://ovms/public/colorization-v2/FP32"
            }
        ]
    }
]
```
### Single model server on single VM 
You can deploy single model server on single VM with configuration below. In short, you need same number of vm as the number of models. This configuration is much more for production use than previous one.
```JSON
[
    {
        "vm_name": "humanpose_vm",
        "vm_size": "Standard_D2s_v4",
        "models": [
            {
                "function_name": "humanpose",
                "model_name": "human-pose-estimation",
                "env_name_ip": "HUMANPOSE_IPADDRESS",
                "env_name_port": "HUMAN_POSE_PORT",
                "port_number": 9000,
                "model_path_on_azure_storage": "az://ovms/intel/human-pose-estimation-0001/FP16-INT8"
            }
        ]
    },
    {
        "vm_name": "handwritten_vm",
        "vm_size": "Standard_D2s_v4",
        "models": [
            {
                "function_name": "handwritten",
                "model_name": "handwritten-japanese-recognition",
                "env_name_ip": "HANDWRITTEN_IPADDRESS",
                "env_name_port": "HAND_WRITTEN_PORT",
                "port_number": 9000,
                "model_path_on_azure_storage": "az://ovms/intel/handwritten-japanese-recognition-0001/FP16-INT8"
            }
        ]
    },
    {
        "vm_name": "colorization_vm",
        "vm_size": "Standard_D2s_v4",
        "models": [
            {
                "function_name": "colorization",
                "model_name": "colorization",
                "env_name_ip": "COLORIZATION_IPADDRESS",
                "env_name_port": "COLORIZATION_PORT",
                "port_number": 9000,
                "model_path_on_azure_storage": "az://ovms/public/colorization-v2/FP32"
            }
        ]
    }
]

```
### Parameter Definitions
1. **vm_name**: a name of Azure VM
1. **models**: a list consisting of model(s) to be deoloyed on the VM named "vm_name"
    1. **function_name**: the name of the corresponding fucntion on Azure functions
    1. **model_name**: a unique name of deployed model on model server
    1. **env_name_ip**: Name of environemnt variable for IP address on Azure Functions
    1. **env_name_port**: Name of environemnt variable for port number on Azure Functions
    1. **port_number**: specific port number for accesing the model
    1. **model_path_on_azure_storage**: The path of model file (IR) on Azure Blob Storage. The format is *az://container_name/folder_name*.

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
- For multiple models on single VM
```Bash
source ./deploy_vm.sh deploy_config_singlevm.json ResourceGroupName  AzureStorageConnectionString
```
- For single model on single VM
```Bash
source ./deploy_vm.sh deploy_config.json ResourceGroupName  AzureStorageConnectionString
```

### Parameters
1. The path of the configuration file
1. Specific name of resource group to be created
1. Azure storage connection string (SAS is also be accepted)

## Delete Resource Group

Use Azure CLI directly as below.

```Bash
az group delete --name ResourceGroupName --y
```
