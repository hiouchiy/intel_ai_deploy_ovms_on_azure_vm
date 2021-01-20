#!/bin/bash

RESOURCE_GROUP=$2
LOCATION=japaneast

AF_RESOURCE_GROUP=OVaaS
AF_NAME=ovaas-backend

ARM_TEMPLATE_FILE=azuredeploy.json

AZURE_STORAGE_CONNECTION_STRING=$3

az group create --name $RESOURCE_GROUP --location $LOCATION

function deploy_vm () {
    i=$1
    row=$(echo $json | jq .[$i])
    echo "Processing $(($i + 1)) row.."

    PARAM_FOR_CUSTOM_SCRIPT=""
    ALL_PORT_NUMBERS=""
    MIN_PORT_NUMBER=""
    MAX_PORT_NUMBER=""
    
    VM_NAME=$(echo $row | jq .vm_name | sed -e 's/^"//' -e 's/"$//')
    echo $VM_NAME
    VM_SIZE=$(echo $row | jq .vm_size | sed -e 's/^"//' -e 's/"$//')
    echo $VM_SIZE
    DEPLOY_TYPE=$(echo $row | jq .deploy_type | sed -e 's/^"//' -e 's/"$//')
    echo $DEPLOY_TYPE

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
        MODEL_SERVER_VERSION=$(echo $models | jq .[$j].model_server_version | sed -e 's/^"//' -e 's/"$//')
        echo $MODEL_SERVER_VERSION

        PARAM_FOR_CUSTOM_SCRIPT="${PARAM_FOR_CUSTOM_SCRIPT} ${PORT_NUMBER},${MODEL_NAME},${MODEL_PATH},${MODEL_SERVER_VERSION}"
        
        if [ $j -eq 0 ]; then
            MIN_PORT_NUMBER=${PORT_NUMBER}
            MAX_PORT_NUMBER=${PORT_NUMBER}
        else
            if [ $PORT_NUMBER -lt $MIN_PORT_NUMBER ]; then
                MIN_PORT_NUMBER=${PORT_NUMBER}
            fi
            
            if [ $PORT_NUMBER -gt $MAX_PORT_NUMBER ]; then
                MAX_PORT_NUMBER=${PORT_NUMBER}
            fi
        fi
    done
    
    if [ $MIN_PORT_NUMBER -eq $MAX_PORT_NUMBER ]; then
        ALL_PORT_NUMBERS="${MAX_PORT_NUMBER}"
    else
        ALL_PORT_NUMBERS="${MIN_PORT_NUMBER}-${MAX_PORT_NUMBER}"
    fi

    echo $PARAM_FOR_CUSTOM_SCRIPT
    echo $ALL_PORT_NUMBERS

    if [ $DEPLOY_TYPE = "vm" ]; then
        DEPLOYMENT_NAME="Deployment_${i}"
        az deployment group create \
            --name $DEPLOYMENT_NAME \
            --resource-group $RESOURCE_GROUP \
            --template-file $ARM_TEMPLATE_FILE \
            --parameters adminUsername=ai adminPasswordOrKey=Passw0rd1234 vmSize=$VM_SIZE portNumber=$ALL_PORT_NUMBERS authenticationType=password customScriptCommandToExecute="sh CUSTOM_SCRIPT_setup_ovms.sh \"${AZURE_STORAGE_CONNECTION_STRING}\" ${PARAM_FOR_CUSTOM_SCRIPT}" vmName=$VM_NAME
    else
        # Create VNet
        az network vnet create \
          --resource-group $RESOURCE_GROUP \
          --name ${VM_NAME}-VNet \
          --address-prefixes 10.1.0.0/16 \
          --subnet-name ${VM_NAME}-BackendSubnet \
          --subnet-prefixes 10.1.0.0/16

        # Create Public IP
        az network public-ip create \
          --resource-group $RESOURCE_GROUP \
          --name ${VM_NAME}-PublicIP \
          --sku Standard
          
        # Create Load Balancer
        az network lb create \
          --resource-group $RESOURCE_GROUP \
          --name ${VM_NAME}-LoadBalancer \
          --sku Standard \
          --backend-pool-name ${VM_NAME}-BackEndPool \
          --frontend-ip-name ${VM_NAME}-FrontEnd \
          --public-ip-address ${VM_NAME}-PublicIP

        # Create VMSS
        az vmss create \
          --resource-group $RESOURCE_GROUP \
          --name ${VM_NAME}-ScaleSetF1Sku \
          --image UbuntuLTS \
          --vm-sku $VM_SIZE \
          --admin-user ai \
          --admin-password Passw0rd1234 \
          --upgrade-policy-mode Automatic \
          --authentication-type password \
          --load-balancer ${VM_NAME}-LoadBalancer \
          --vnet-name ${VM_NAME}-VNet \
          --subnet ${VM_NAME}-BackendSubnet \
          --scale-in-policy OldestVM

        # Install Custom Script
        az vmss extension set \
          --vmss-name ${VM_NAME}-ScaleSetF1Sku \
          --publisher Microsoft.Azure.Extensions \
          --version 2.0 \
          --name CustomScript \
          --resource-group $RESOURCE_GROUP \
          --settings '{"fileUris": ["https://raw.githubusercontent.com/hiouchiy/intel_ai_deploy_ovms_on_azure_vm/main/CUSTOM_SCRIPT_setup_ovms.sh"],"commandToExecute": "sh /var/lib/waagent/custom-script/download/1/CUSTOM_SCRIPT_setup_ovms.sh \"${AZURE_STORAGE_CONNECTION_STRING}\" ${PARAM_FOR_CUSTOM_SCRIPT}"}'

        # Create Auto Scale setting （The num of VM instance is MIN:2 and MAX:10）
        az monitor autoscale create \
          --resource-group $RESOURCE_GROUP \
          --resource ${VM_NAME}-ScaleSetF1Sku \
          --resource-type Microsoft.Compute/virtualMachineScaleSets \
          --name ${VM_NAME}-autoscale \
          --min-count 2 \
          --max-count 10 \
          --count 2

        # Create Auto Scale rule （過去５分の平均CPU使用率が70％以上の場合、インスタンスを3つ作成）
        az monitor autoscale rule create \
          --resource-group $RESOURCE_GROUP \
          --autoscale-name ${VM_NAME}-autoscale \
          --condition "Percentage CPU > 70 avg 5m" \
          --scale out 3

        # Create Auto Scale rule （過去５分の平均CPU使用率が30％未満に場合、インスタンスを1つ削除）
        az monitor autoscale rule create \
          --resource-group $RESOURCE_GROUP \
          --autoscale-name ${VM_NAME}-autoscale \
          --condition "Percentage CPU < 30 avg 5m" \
          --scale in 1
    fi
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
    DEPLOY_TYPE=$(echo $row | jq .deploy_type | sed -e 's/^"//' -e 's/"$//')
    echo $DEPLOY_TYPE
    
    if [ $DEPLOY_TYPE = "vm" ]; then
        IP_ADDRESS=`az vm list-ip-addresses -g $RESOURCE_GROUP -n $VM_NAME -o json | jq -r .[].virtualMachine.network.publicIpAddresses[0].ipAddress`
    else
        IP_ADDRESS=`az network lb frontend-ip list --lb-name ${VM_NAME}-LoadBalancer --resource-group $RESOURCE_GROUP -o json | jq -r .[].virtualMachine.network.publicIpAddresses[0].ipAddress`
    fi

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
