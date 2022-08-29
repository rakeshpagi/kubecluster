#!/bin/bash

# INSTALL HELM IF NOT PRESENT
cd $HOME
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

helm --version 

#INSTALL NGINX INGRESS VIA HELM 
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
  
 
# ADD INGRESS RULE 
# kubectl create ingress hello-ingress --class=nginx -n namespace --rule="helloworld.com/=hello-service:8080"
