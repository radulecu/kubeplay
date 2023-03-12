#!/bin/bash

# install istio demo profile, see more details here: https://istio.io/latest/docs/setup/install/istioctl/
#vagrant ssh master -c "curl -L https://istio.io/downloadIstio | sh - && export PATH=~/istio-1.15.3/bin:$PATH && istioctl install -y"
#kubectl create deployment demo --image=httpd --port=80
#kubectl expose deployment demo
#kubectl create ingress demo-localhost --class=nginx \
#  --rule="demo.localdev.me/*=demo:80"
#kubectl port-forward --namespace=istio-system service/istio-ingressgateway 8080:80

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
#kubectl create deployment demo --image=httpd --port=80
#kubectl expose deployment demo
#kubectl create ingress demo-localhost --class=nginx \
#  --rule="demo.localdev.me/*=demo:80"
#kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
kubectl apply -f ingress-service.yaml