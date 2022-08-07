#!/bin/bash
getenforce 

setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# Setting Up Kube-Master-1 
dnf update -y
 
# Restart VM here  

hostname master1
#change HostName in /etc/hosts 

echo 'Install and Enable ipvsadm'
yum install -y ipvsadm 

mkdir -p /etc/sysconfig/ipvsadm

systemctl enable ipvsadmd
systemctl start ipvsadm

#Load Modules
modprobe overlay
modprobe br_netfilter

# Add Rule :  net.bridge.bridge-nf-call-iptables = 1 , net.ipv4.ip_forward = 1  
cat >> /etc/sysctl.conf <<EOF
 net.bridge.bridge-nf-call-iptables = 1
 net.ipv4.ip_forward = 1
EOF
sysctl --system 

echo 'Install containerd.io'
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum install  containerd.io -y 

containerd config default > /etc/containerd/config.toml

systemctl enable containerd
systemctl start containerd 
systemctl status containerd 


##DISABLE SWAP  
swapoff -a 

echo "Edit /etc/fstab and Remove Swap Entry"

echo "[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
#gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repo.d/kubernetes.repo

yum update
yum search kubeadm
yum install -y kubeadm 

# If Any Error then remove gpgkey -> Save and Yum Install Again 

yum install  -y  kubeadm 

#Enable KubeLet 
systemctl enable kubelet 
## Normal User FROM HERE 
sudo kubeadm config images pull 

sudo kubeadm config print init-defaults > kubeadm.yaml

vi kubeadm.yaml

sudo  kubeadm init --config kubeadm.yaml | tee > postinstall.txt

echo "Master Initiated "
echo "Grant Priv to VM user "
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config



#Download Calico CNI
curl https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml
#Apply Calico CNI
kubectl apply -f ./calico.yaml


####If you are setting up worker nodes, copy the join command you got after inializing the cluster and run on each node.

#Copy the "/.kube" folder to your worker nodes. That will enable you to run "kubectl" commands from your worker nodes.    
    #scp -r $HOME/.kube gary@192.168.0.23:/home/gary

#Get cluster info
kubectl cluster-info

#If you have a single Kubernetes node (only master), untaint it so you can schedule PODS on it
kubectl taint node kube-master node-role.kubernetes.io/master-

#View nodes
kubectl get nodes -o wide

#List the virtual server table 
sudo ipvsadm -L

#Schedule a Kubernetes deployment using a container from Google samples
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0

#View all Kubernetes deployments
kubectl get deployments

kubectl expose deployment hello-world --port=8090 --target-port=8080 

kubectl get services

kubectl get pods -o wide

#List the virtual server table
sudo ipvsadm -L

kubectl scale --replicas=4 deployment/hello-world

#List the virtual server table
sudo ipvsadm -L