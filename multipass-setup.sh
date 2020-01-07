#!/bin/bash
NAME=ubuntu-multipass
CPU=4
MEM=6G
DISK=10G

## unset any proxy env vars
unset PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

## install commands here
cat <<'EOF' > multipass-commands.txt
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common jq git wget
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt install -y docker-ce
sudo usermod -aG docker ubuntu
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
bash get_helm.sh
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list 
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
curl -O https://storage.googleapis.com/golang/go1.13.linux-amd64.tar.gz
echo "export GOPATH=$HOME/go" >> ~/.bashrc
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bashrc
tar -xf go1.13.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local
GO111MODULE="on" /usr/local/go/bin/go get sigs.k8s.io/kind@v0.6.1
echo "done"
EOF

## launch multipass
multipass launch ubuntu --name $NAME --cpus $CPU --mem $MEM --disk $DISK
multipass list | egrep "^ubuntu-multipass" | grep Running
if [ $? -ne 0 ]; then 
   exit 1
fi

## loop thru commands
sleep 10
cat multipass-commands.txt | while read line
do 
  multipass exec $NAME -- bash -c ''"$line"''
done
rm multipass-commands.txt

## copy files prefaced with "multipass" into the multipass instance
multipass copy-files multipass* $NAME:
