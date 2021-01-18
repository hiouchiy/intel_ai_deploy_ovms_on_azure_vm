#!/bin/sh

AZURE_STORAGE_CONNECTION_STRING=$1

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}

mkdir /log

for i in `seq 1 ${#}`
do

    if [ ${i} -eq 1 ]; then
        shift
        continue
    fi
    
    PORT_NUMBER=`echo ${1} | cut -d , -f 1`
    MODEL_NAME=`echo ${1} | cut -d , -f 2`
    MODEL_PATH=`echo ${1} | cut -d , -f 3`
    echo "$PORT_NUMBER $MODEL_NAME $MODEL_PATH"
    
    sudo docker run --rm -d -v /log:/log -p $PORT_NUMBER:9000 -e AZURE_STORAGE_CONNECTION_STRING=$AZURE_STORAGE_CONNECTION_STRING openvino/model_server:latest --model_path $MODEL_PATH --model_name $MODEL_NAME --port 9000 --log_level DEBUG --log_path /log

    shift
done
