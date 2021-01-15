#!/bin/bash

RESOURCE_GROUP=$2
LOCATION=japaneast

AF_RESOURCE_GROUP=OVaaS
AF_NAME=ovaas-backend

ARM_TEMPLATE_FILE=$3

AZURE_STORAGE_CONNECTION_STRING=$4

az group create --name $RESOURCE_GROUP --location $LOCATION

function deploy_vm () {
    i=$1
    row=$(echo $json | jq .[$i])
    echo "Processing $(($i + 1)) row.."

    PARAM_FOR_CUSTOM_SCRIPT=""
    
    VM_NAME=$(echo $row | jq .vm_name | sed -e 's/^"//' -e 's/"$//')
    echo $VM_NAME

    models=$(echo $row | jq .models)
    models_len=$(echo $models | jq length)
    for j in $( seq 0 $(($models_len - 1)) ); do
        AF_FUNC_NAME=$(echo $models | jq .[$j].function_name | sed -e 's/^"//' -e 's/"$//')
        echo $AF_FUNC_NAME
        MODEL_NAME=$(echo $models | jq .[$j].model_name | sed -e 's/^"//' -e 's/"$//')
        echo $MODEL_NAME
        PORT_NUMBER=$(echo $models | jq .[$j].port_number)
        echo $PORT_NUMBER
        MODEL_PATH=$(echo $models | jq .[$j].model_path_on_azure_storage | sed -e 's/^"//' -e 's/"$//')
        echo $MODEL_PATH

        PARAM_FOR_CUSTOM_SCRIPT="${PARAM_FOR_CUSTOM_SCRIPT} ${PORT_NUMBER},${MODEL_NAME},${MODEL_PATH}"
    done

    echo $PARAM_FOR_CUSTOM_SCRIPT

    DEPLOYMENT_NAME="Deployment_${i}"
    az deployment group create --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --template-file $ARM_TEMPLATE_FILE --parameters adminUsername=ai adminPasswordOrKey=Passw0rd1234 vmSize=Standard_D2s_v4 authenticationType=password customScriptCommandToExecute="sh CUSTOM_SCRIPT_setup_ovms.sh \"${AZURE_STORAGE_CONNECTION_STRING}\" ${PARAM_FOR_CUSTOM_SCRIPT}" vmName=$VM_NAME
}

json=$(cat $1)
len=$(echo $json | jq length)
for i in $( seq 0 $(($len - 1)) ); do
    deploy_vm $i &
    pid_list[${i}]=$!
    sleep 5
done

for pid in ${pid_list[@]}; do
    wait $pid
    sc=$?
    if [ 0 -ne $sc ]; then
        echo "[error] pid=$pid finished with status code $sc"
#        for pid2 in ${pid_list[@]}; do
#            kill -KILL $pid2
#        done
#        exit 1
    else
        echo "[info] pid=$pid finished"
    fi
done

echo "[info] -----------------------------"
echo "[info] finished all background proc."

for i in $( seq 0 $(($len - 1)) ); do
    row=$(echo $json | jq .[$i])
    VM_NAME=$(echo $row | jq .vm_name | sed -e 's/^"//' -e 's/"$//')
    echo $VM_NAME
    
    IP_ADDRESS=`az vm list-ip-addresses -g $RESOURCE_GROUP -n $VM_NAME -o json | jq -r .[].virtualMachine.network.publicIpAddresses[0].ipAddress`

    models=$(echo $row | jq .models)
    models_len=$(echo $models | jq length)
    for j in $( seq 0 $(($models_len - 1)) ); do
        AF_IP_ADDRESS_NAME=$(echo $models | jq .[$j].env_name_ip | sed -e 's/^"//' -e 's/"$//')
        echo $AF_IP_ADDRESS_NAME
        AF_PORT_NAME=$(echo $models | jq .[$j].env_name_port | sed -e 's/^"//' -e 's/"$//')
        echo $AF_PORT_NAME
        PORT_NUMBER=$(echo $models | jq .[$j].port_number)
        echo $PORT_NUMBER

        az functionapp config appsettings set --name $AF_NAME  --resource-group $AF_RESOURCE_GROUP --settings "$AF_IP_ADDRESS_NAME=$IP_ADDRESS" "$AF_PORT_NAME=$PORT_NUMBER"
    done
done
