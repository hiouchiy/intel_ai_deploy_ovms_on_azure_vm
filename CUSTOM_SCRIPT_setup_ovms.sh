#!/bin/sh

PORT_NUMBER=$1
MODEL_NAME=$2
MODEL_PATH=$3
AZURE_STORAGE_CONNECTION_STRING=$4

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
sudo docker run --rm -d -p $PORT_NUMBER:$PORT_NUMBER -e AZURE_STORAGE_CONNECTION_STRING=$AZURE_STORAGE_CONNECTION_STRING openvino/model_server:latest --model_path $MODEL_PATH --model_name $MODEL_NAME --port $PORT_NUMBER
