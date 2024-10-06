#!/bin/bash
set -e

#########################################################
# 이 스크립트는 다음과 같은 작업을 자동화합니다:
# 1. SSH 설정 업데이트
# 2. developer 사용자 계정 생성 및 권한 설정
# 3. Docker 및 AWS CLI 버전 2 설치
# 주요 기능:
# - 호스트네임 기반으로 SSH 키 생성 및 설정
# - 필요한 소프트웨어 패키지 설치
# - Docker 및 AWS CLI 환경 구성
# 사용된 커맨드와 설정은 Ubuntu, Debian, CentOS 및 Fedora를 포함한
# 스크립트는 특정 아키텍처(amd64)와 플랫폼(Linux)에 대해서만 설계되었습니다. 
#########################################################

# SSH 설정 업데이트: root 로그인을 비밀번호 없이 키 기반으로 제한
read -s -p "Enter [developer] password: " password

HOSTNAME=$(hostname -f)
KEY_NAME="${HOSTNAME}_rsa"
SSHD_CONFIG="/etc/ssh/sshd_config"
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' $SSHD_CONFIG
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' $SSHD_CONFIG
# AuthenticationMethods 설정: key + password 인증을 모두 요구
if ! grep -q "^AuthenticationMethods publickey,password" $SSHD_CONFIG; then
    echo "AuthenticationMethods publickey,password" | sudo tee -a $SSHD_CONFIG
fi

sudo systemctl restart sshd

# 새 사용자 계정 생성: developer
# 비밀번호 없이 계정을 생성하고 sudo 권한을 부여
sudo adduser developer --disabled-password --gecos ""
echo "developer:$password" | sudo chpasswd
echo "developer ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/init-developer

# SSH 키 생성 및 권한 설정
sudo mkdir -p /home/developer/.ssh
sudo ssh-keygen -t rsa -b 4096 -f /home/developer/.ssh/$KEY_NAME -N ''
sudo cat /home/developer/.ssh/${KEY_NAME}.pub | sudo tee -a /home/developer/.ssh/authorized_keys
sudo chown -R developer:developer /home/developer/.ssh
sudo chmod 700 /home/developer/.ssh
sudo chmod 600 /home/developer/.ssh/authorized_keys
sudo chmod 600 /home/developer/.ssh/${KEY_NAME}
sudo chmod 644 /home/developer/.ssh/${KEY_NAME}.pub

# Docker 및 AWS CLI 설치 함수
install_docker_and_awscli() {
    sudo apt-get update
    sudo apt-get install -y git unzip apt-transport-https ca-certificates curl software-properties-common
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    curl -fsSL https://download.docker.com/linux/$1/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$1 $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

# OS 감지 및 적절한 설치 실행
detect_and_install() {
    OS=$(uname -s)
    if [[ "$OS" == "Linux" ]]; then
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    install_docker_and_awscli "ubuntu"
                    ;;
                centos|rhel|fedora)
                    install_docker_and_awscli "centos"
                    ;;
                *)
                    echo "Unsupported Linux distribution: $ID"
                    exit 1
                    ;;
            esac
        fi
    else
        echo "Unsupported OS: $OS"
        exit 1
    fi
}

# Docker 서비스 시작 및 활성화
start_docker() {
    sudo systemctl start docker
    sudo systemctl enable docker
}

# 설치 검증
verify_installation() {
    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker service is not running"
        exit 1
    fi
    if ! aws --version; then
        echo "AWS CLI is not installed properly"
        exit 1
    fi
}

# 재시도 로직
retry_logic() {
    local n=1
    local max=3
    local delay=5
    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                echo "Command failed. Attempt $n/$max:"
                sleep $delay;
            else
                echo "The command has failed after $n attempts."
                return 1
            fi
        }
    done
}

# 스크립트 실행
retry_logic detect_and_install
start_docker
verify_installation

sudo usermod -aG docker developer

echo "설정이 완료되었습니다."
