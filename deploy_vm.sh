#!/bin/sh

RESOURCE_GROUP=$2
LOCATION=japaneast

AF_RESOURCE_GROUP=OVaaS
AF_NAME=ovaas-backend

ARM_TEMPLATE_FILE=azuredeploy.json

az group create --name $RESOURCE_GROUP --location $LOCATION

while read row; do
    if [ -z "${row}" ]; then
        break
    fi

    AF_FUNC_NAME=`echo ${row} | cut -d , -f 1`
    MODEL_NAME=`echo ${row} | cut -d , -f 2`
    VM_NAME=`echo ${row} | cut -d , -f 3`
    AF_IP_ADDRESS_NAME=`echo ${row} | cut -d , -f 4`
    AF_PORT_NAME=`echo ${row} | cut -d , -f 5`
    PORT_NUMBER=`echo ${row} | cut -d , -f 6`
    MODEL_PATH=`echo ${row} | cut -d , -f 7`
    ARM_PARAMETER_FILE=`echo ${row} | cut -d , -f 8`

    az deployment group create --name ExampleDeployment --resource-group $RESOURCE_GROUP --template-file $ARM_TEMPLATE_FILE --parameters adminUsername=ai adminPasswordOrKey=Passw0rd1234 vmSize=Standard_D2s_v4 authenticationType=password customScriptCommandToExecute="sh setup_ovms.sh ${PORT_NUMBER} ${MODEL_NAME} ${MODEL_PATH}" vmName=$VM_NAME

    IP_ADDRESS=`az vm list-ip-addresses -g $RESOURCE_GROUP -n $VM_NAME -o json | jq -r .[].virtualMachine.network.publicIpAddresses[0].ipAddress`

    az functionapp config appsettings set --name $AF_NAME  --resource-group $AF_RESOURCE_GROUP --settings "$AF_IP_ADDRESS_NAME=$IP_ADDRESS" "$AF_PORT_NAME=$PORT_NUMBER"
  
done < $1
