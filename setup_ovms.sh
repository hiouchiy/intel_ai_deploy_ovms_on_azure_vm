#/bin/sh

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
sudo docker run --rm -d -p 9000:9000 -e AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=ovaasstorage;AccountKey=1+htUw4UA7P0h5lUfiYZcqJNJYmM+HMONOEDrhhWGApJXWoch95lmPG4ub277+PEGv4wYNkSWrlrUwJqPEn1Vg==;EndpointSuffix=core.windows.net" openvino/model_server:latest --model_path az://ovms/intel/human-pose-estimation-0001/FP16-INT8 --model_name human-pose-estimation --port 9000
