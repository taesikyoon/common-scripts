#!/bin/bash
set -e

## 주의 사항
### *.gguf 파일이 있어야함 (실제 모델파일! 꼭 필요함) ,,, EX) llama-2-7b-project-ep2-gguf-unsloth.Q4_K_M.gguf
### 
##################################################################################################################
# REF = https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installation #
# Alloma 컨테이너 띄우기 전 필요한 세팅                                                                                 #
##################################################################################################################

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker

network_name="your network name"
model_name="your model name"
container_modelfile_path="your file path"

# 도커 네트워크 생성
if ! docker network ls | grep -q "${network_name}"; then
    echo "Docker 네트워크 '${network_name}'가 존재하지 않습니다. 새 네트워크를 생성합니다."
    docker network create ${network_name}
else
    echo "Docker 네트워크 '${network_name}'가 이미 존재합니다."
fi

# 모델파일 경로
# ex /home/shared_directory/scenario-engine-model
host_modelfile_path="your host path"
mkdir -p $host_modelfile_path


# -v [호스트 내부 경로]:[컨테이너 내부 경로]
docker run -d --gpus=all -v ollama:/root/.ollama -v /home/shared_directory/scenario-engine-model:/scenario-engine --network $network_name -p 11434:11434 --name ollama ollama/ollama

# 모델 생성 (EX ollama create oddnary-model -f /scenario-engine-model/Modelfile)
docker exec ollama create $model_name -f $container_modelfile_path