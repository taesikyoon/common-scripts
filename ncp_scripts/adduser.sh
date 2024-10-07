#!/bin/bash
set -e

HOSTNAME=$(hostnamectl --static)

read -p "Enter username: " username
read -s -p "Enter password: " password

# 사용자 생성
sudo adduser --disabled-password --gecos "" "$username"
echo "$username:$password" | sudo chpasswd

# 기본 그룹을 'developer'로 변경
sudo usermod -g developer $username
# SSH 디렉토리 설정
sudo mkdir -p /home/"$username"/.ssh

# PEM 키 파일 이름: $hostname_$username_rsa
key_filename="${HOSTNAME}_${username}_rsa"

read -s -p "Enter Key Comment or Description : " comment

# SSH 키 생성
sudo ssh-keygen -t rsa -b 4096 -C "${comment}" -f /home/"$username"/.ssh/"$key_filename" -N ""
sudo cat /home/"$username"/.ssh/"$key_filename".pub | sudo tee -a /home/"$username"/.ssh/authorized_keys

# SSH 디렉토리 및 파일 권한 설정
sudo chown -R "$username":"$username" /home/"$username"/.ssh
sudo chmod 700 /home/"$username"/.ssh
sudo chmod 600 /home/"$username"/.ssh/authorized_keys
sudo chmod 600 /home/"$username"/.ssh/"$key_filename"

echo ""
echo "User '$username' created with key-based and password authentication."
echo "Private key saved to /home/$username/.ssh/$key_filename."

echo ""
cat /home/"$username"/.ssh/"$key_filename"

# Delete
# sudo userdel -r "username"
# sudo groupdel "username"
