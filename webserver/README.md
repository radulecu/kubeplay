# NGINX Webserver example

    kubectl create -f webserver.yaml
    
## Create service

    kubectl expose deployment webserver --name=web-service --type=NodePort

or with a file

    kubectl create -f webserver-svc.yaml

## Access page

    curl $(minikube ip):<port>

or

    minikube service web-service

where port is found under NodePort field on:

     kubectl describe service web-service