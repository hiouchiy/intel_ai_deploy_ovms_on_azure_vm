#!/bin/sh

PORT_NUMBER=$1
MODEL_NAME=$2
MODEL_PATH=$3
AZURE_STORAGE_CONNECTION_STRING="SharedAccessSignature=sv=2018-03-28&ss=b&srt=sco&sp=rl&st=2021-01-01T00%3A55%3A39Z&se=2022-01-01T00%3A55%3A00Z&sig=qA38onoiJMjX3dIDOBnELWTs2yNjNDQNtnRb1vz5068%3D;BlobEndpoint=https://ovaasstorage.blob.core.windows.net/;"

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
#sudo docker run --rm -d -p 9000:9000 -e AZURE_STORAGE_CONNECTION_STRING="SharedAccessSignature=sv=2018-03-28&ss=b&srt=sco&sp=rl&st=2021-01-01T00%3A55%3A39Z&se=2022-01-01T00%3A55%3A00Z&sig=qA38onoiJMjX3dIDOBnELWTs2yNjNDQNtnRb1vz5068%3D;BlobEndpoint=https://ovaasstorage.blob.core.windows.net/;" openvino/model_server:latest --model_path az://ovms/intel/human-pose-estimation-0001/FP16-INT8 --model_name human-pose-estimation --port 9000
sudo docker run --rm -d -p $PORT_NUMBER:$PORT_NUMBER -e AZURE_STORAGE_CONNECTION_STRING=$AZURE_STORAGE_CONNECTION_STRING openvino/model_server:latest --model_path $MODEL_PATH --model_name $MODEL_NAME --port $PORT_NUMBER
