#!/bin/sh

AZURE_STORAGE_CONNECTION_STRING=$1

sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
mkdir /home/ai/log
chmod 777 /home/ai/log

for i in `seq 1 ${#}`
do

    if [ ${i} -eq 1 ]; then
        shift
        continue
    fi
    
    PORT_NUMBER=`echo ${1} | cut -d , -f 1`
    MODEL_NAME=`echo ${1} | cut -d , -f 2`
    MODEL_PATH=`echo ${1} | cut -d , -f 3`
    MODEL_SERVER_VERSION=`echo ${1} | cut -d , -f 4`
    echo "$PORT_NUMBER $MODEL_NAME $MODEL_PATH $MODEL_SERVER_VERSION"
    
    sudo docker run --rm -d -v /home/ai/log:/log -p $PORT_NUMBER:9000 -e AZURE_STORAGE_CONNECTION_STRING=$AZURE_STORAGE_CONNECTION_STRING openvino/model_server:$MODEL_SERVER_VERSION --model_path $MODEL_PATH --model_name $MODEL_NAME --port 9000 --log_level DEBUG --log_path "/log/${MODEL_NAME}.log"

    shift
done
