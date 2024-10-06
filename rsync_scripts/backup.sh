#!/bin/bash
#######################################################
# 데이터 이전을 위한 전체 실행 스크립트                        #
# setup_ssh_config.sh, transfer_pem_key.sh 스크립트 사용 #
#######################################################

set -e

# 색상 코드 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

normalize_input() {
    case "$1" in
        [Yy] | [Yy][Ee][Ss])
            echo "yes"
            ;;
        [Nn] | [Nn][Oo])
            echo "no"
            ;;
        *)
            echo "no"
            ;;
    esac
}

# config 파일이 있는지 확인
if [ ! -f ~/.ssh/config ]; then
    echo -e "${RED}SSH configuration file not found. Creating it now...${NC}"
    touch ~/.ssh/config
else
    echo -e "${GREEN}SSH configuration file exists. Proceeding...${NC}"
fi


# SSH 호스트 설정 이름 입력 받기
echo -e "${GREEN}Checking SSH configuration...${NC}"
cat ~/.ssh/config

echo -e "${GREEN}Enter the host name for this SSH configuration to check: ${NC}"
read host_name

# Check if the SSH configuration exists
if grep -q "Host $host_name" ~/.ssh/config; then
    echo -e "${GREEN}SSH configuration for '$host_name' found. Proceeding with file transfer...${NC}"
else
    echo -e "${RED}SSH configuration for '$host_name' not found.${NC}"
    echo -e "${RED}Would you like to run the setup_ssh_config.sh script to set up SSH configuration now? (yes/no)${NC}"
    read setup_choice
    setup_choice=$(normalize_input "$setup_choice")
    if [[ $setup_choice == "yes" ]]; then
        ./setup_ssh_config.sh
        cat ~/.ssh/config
        echo -e "${GREEN}Please re-enter the host name after setup: ${NC}"
        read host_name
    else
        echo -e "${RED}Exiting script as SSH configuration is necessary to proceed.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Do you need to copy data from inside the Docker container to the host? (yes/no): ${NC}"
read copy_data

copy_data=$(normalize_input "$copy_data")

if [[ $copy_data == "no" ]]; then
    echo -e "${GREEN}No need to move data from inside the container. Proceed with the next steps.${NC}"
else
    echo -e "${GREEN}Current running containers:${NC}"
    docker ps

    echo -e "${GREEN}Please enter the Docker container name: ${NC}"
    read container_name
    echo -e "${GREEN}Enter the path of data inside the container: ${NC}"
    read container_data_path
    echo -e "${GREEN}Enter the path on the host to store data: ${NC}"
    read host_data_path

    # Copy data from container to host
    docker cp ${container_name}:${container_data_path} ${host_data_path}
    echo "Data copied from container to host."
fi

# Input for file transfer
echo -e "${GREEN}Enter the source path on the host: ${NC}"
read source_path
echo -e "${GREEN}Enter the destination path on the remote server: ${NC}"
read destination_path
echo -e "${GREEN}Enter the SSH configuration name (from .ssh/config): ${NC}"
read ssh_config_name

# Perform rsync
rsync -avz ${source_path} ${ssh_config_name}:${destination_path}


# PEM 키 전송 여부 확인
echo -e "${GREEN}Do you want to transfer the PEM key as well? (yes/no): ${NC}"
read transfer_pem
transfer_pem=$(normalize_input "$transfer_pem")

if [[ $transfer_pem == "yes" ]]; then
    # 세 번째 스크립트 호출
    ./transfer_pem_key.sh $ssh_config_name
else
    echo "Files have been transferred. Exiting script."
fi
