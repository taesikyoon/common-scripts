#!/bin/bash
#######################################################
#            SSH 설정을 위한 전체 실행 스크립트              #
#######################################################

set -e

# 색상 코드 정의
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# RSA Key 파일 이름, 메모, 호스트 명칭, 포트 번호 입력 받기
echo -e "${GREEN}Enter the RSA key filename (without extension): ${NC}"
read key_filename
echo -e "${GREEN}Enter a comment for the key (e.g., email or description): ${NC}"
read key_comment
echo -e "${GREEN}Enter the SSH port (default 22): ${NC}"
read ssh_port

# 기본값 설정
ssh_port=${ssh_port:-22}

# RSA Key 생성
echo "Generating RSA key with comment..."
ssh-keygen -t rsa -b 4096 -N "" -C "${key_comment}" -f ~/.ssh/${key_filename}

# Public Key를 target 인스턴스로 복사
echo "Copying public key to the target instance..."
echo -e "${GREEN}Enter target username: ${NC}"
read target_user
echo -e "${GREEN}Enter target IP or domain name: ${NC}"
read target_host

# .ssh/config 파일이 없으면 생성
if [ ! -f ~/.ssh/config ]; then
    echo "SSH configuration file not found. Creating it now..."
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config  # config 파일에 대한 적절한 권한 설정
fi

ssh-copy-id -i ~/.ssh/${key_filename}.pub -p ${ssh_port} ${target_user}@${target_host}

# .ssh/config 파일에 SSH 정보 등록
echo "Configuring SSH details in .ssh/config..."
echo -e "${GREEN}Enter the host name for this SSH configuration: ${NC}"
read host_name

echo -e "Host ${host_name}\n\tHostName ${target_host}\n\tUser ${target_user}\n\tPort ${ssh_port}\n\tIdentityFile ~/.ssh/${key_filename}" >> ~/.ssh/config

echo "SSH configuration completed."
