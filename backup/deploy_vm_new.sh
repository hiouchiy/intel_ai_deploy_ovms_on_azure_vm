#!/bin/sh

RESOURCE_GROUP=$2
LOCATION=japaneast

AF_RESOURCE_GROUP=OVaaS
AF_NAME=ovaas-backend

ARM_TEMPLATE_FILE=azuredeploy.json

AZURE_STORAGE_CONNECTION_STRING=$3

az group create --name $RESOURCE_GROUP --location $LOCATION

json=$(cat $1)                                                                                                   
len=$(echo $json | jq length)                                                                                           
for i in $( seq 0 $(($len - 1)) ); do                                                                                     
    echo "Processing $(($i + 1)) row.."                                                                                     
    row=$(echo $json | jq .[$i])                                                                                            
    AF_FUNC_NAME=$(echo $row | jq .function_name | sed -e 's/^"//' -e 's/"$//')                                                                          
    echo $AF_FUNC_NAME                                                                                                     
    MODEL_NAME=$(echo $row | jq .model_name | sed -e 's/^"//' -e 's/"$//')                                                                                
    echo $MODEL_NAME                                                                                                        
    VM_NAME=$(echo $row | jq .vm_name | sed -e 's/^"//' -e 's/"$//')                                                                                      
    echo $VM_NAME                                                                                                           
    AF_IP_ADDRESS_NAME=$(echo $row | jq .env_name_ip | sed -e 's/^"//' -e 's/"$//')                                                                              
    echo $AF_IP_ADDRESS_NAME                                                                                                       
    AF_PORT_NAME=$(echo $row | jq .env_name_port | sed -e 's/^"//' -e 's/"$//')                                                                          
    echo $AF_PORT_NAME                                                                                                     
    PORT_NUMBER=$(echo $row | jq .port_number)                                                                              
    echo $PORT_NUMBER                                                                                                       
    MODEL_PATH=$(echo $row | jq .model_path_on_azure_storage | sed -e 's/^"//' -e 's/"$//')                                              
    echo $MODEL_PATH                                                                                     

    az deployment group create --name ExampleDeployment --resource-group $RESOURCE_GROUP --template-file $ARM_TEMPLATE_FILE --parameters adminUsername=ai adminPasswordOrKey=Passw0rd1234 vmSize=Standard_D2s_v4 authenticationType=password customScriptCommandToExecute="sh CUSTOM_SCRIPT_setup_ovms.sh ${PORT_NUMBER} ${MODEL_NAME} ${MODEL_PATH} \"${AZURE_STORAGE_CONNECTION_STRING}\"" vmName=$VM_NAME

    IP_ADDRESS=`az vm list-ip-addresses -g $RESOURCE_GROUP -n $VM_NAME -o json | jq -r .[].virtualMachine.network.publicIpAddresses[0].ipAddress`

    az functionapp config appsettings set --name $AF_NAME  --resource-group $AF_RESOURCE_GROUP --settings "$AF_IP_ADDRESS_NAME=$IP_ADDRESS" "$AF_PORT_NAME=$PORT_NUMBER"
  
done
