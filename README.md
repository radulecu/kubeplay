# Minikube

## Tools

### Kubectl

Install Kubectl details: https://kubernetes.io/docs/tasks/tools/install-kubectl/

Example:

    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    kubectl version --client

### Install Minikube

Minikube is installed and runs directly on a local Linux, macOS, or Windows workstation. However, in order to fully take advantage of all the features Minikube has to offer, a Type-2 Hypervisor should be installed on the local workstation, to run in conjunction with Minikube.
Alternatively you can also install docker and k8s will run on it.

    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.12.2/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

#### Start Minikube

    minikube start

or you can start it as a [multi-node][https://minikube.sigs.k8s.io/docs/tutorials/multi_node/]

    minikube start --nodes 4

#### Add Minikube node

    minikube nodde add

#### Check Minikube

    minikube status

    kubectl cluster-info

    kubectl get deploy,rs,po --all-namespaces

#### Stop Minikube

    minikube stop

#### Start Dashboard

    minikube dashboard

#### Start Minikube and kubernetes proxy

	nohup kubectl proxy &
	xdg-open "http://localhost:8001/api/v1/namespaces"
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml
	xdg-open "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default"
	TOKEN=$(kubectl -n kube-system describe secret default| awk '$1=="token:"{print $2}')
	kubectl config set-credentials kubernetes-admin --token="${TOKEN}"
	kubectl config view

It may take few minutes for the dashboard to load.

To authenticate use TOKEN from above.

#### Proxy URLs
* http://localhost:
* http://localhost:8001/api/v1
* http://localhost:8001/apis/apps/v1
* http://localhost:8001/healthz
* http://localhost:8001/metrics

#### Curl example to directly access the server (no proxy required)

    TOKEN=$(kubectl describe secret -n kube-system $(kubectl get secrets -n kube-system | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t' | tr -d " ")
    APISERVER=$(kubectl config view | grep https | cut -f 2- -d ":" | tr -d " ")
    curl $APISERVER --header "Authorization: Bearer $TOKEN" --insecure

### Manual install using vagrant and virtualbox

Read more at https://medium.com/swlh/setup-own-kubernetes-cluster-via-virtualbox-99a82605bfcc

You need to install vagrant and virtualbox.
vagrant files are in vagrant/k8s-cluster

    vagrant up

#### Configure Master

Connect to the master

    vagrant ssh master

Initialise the master then follow the steps for configuration

    sudo su

    kubeadm init --apiserver-advertise-address 192.168.33.13 --pod-network-cidr=10.244.0.0/16 | tee  kubeadm-init.txt
    
    sudo chown $(id -u):$(id -g) $HOME/kubeadm-init.txt

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

Check status:

    kubectl get nodes

Status will be not ready because we did not apply any network plugin.

#### Configure Network and Network policy addon:

* Weave Net 

https://www.weave.works/docs/net/latest/kubernetes/kube-addon/

    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

* Antrea

https://github.com/antrea-io/antrea/blob/main/docs/getting-started.md

    kubectl apply -f https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/antrea.yml

* Flannel:

    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#### Configure  worker nodes

Connect to workers;

    vagrant ssh worker-1
    
Run the command below as root with the token provided by the master

    kubeadm join 192.168.33.13:6443 --token bx86lo.agyszwr53ow5y53u \
      --discovery-token-ca-cert-hash sha256:536b10417f411de9ff9f11cb83d286f9217f5031845df93355b3a6a5ed96c066

#### Testing

    kubectl create deployment nginx --image=nginx --port 80
    kubectl expose deployment nginx --port 80 --type=NodePort
    echo service started with port $(kubectl get services | grep nginx | awk '{print $5}' | sed -E 's/80:(.*)\/TCP/\1/')
    echo curl 192.168.33.13:$(kubectl get services | grep nginx | awk '{print $5}' | sed -E 's/80:(.*)\/TCP/\1/')
    curl 192.168.33.13:$(kubectl get services | grep nginx | awk '{print $5}' | sed -E 's/80:(.*)\/TCP/\1/')

    kubectl create deployment webserver --image=nginx --port 80 --replicas=5
    kubectl expose deployment webserver --port 80 --type=NodePort
    echo service started with port $(kubectl get services | grep webserver | awk '{print $5}' | sed -E 's/80:(.*)\/TCP/\1/')
    echo curl 192.168.33.13:$(kubectl get services | grep webserver | awk '{print $5}' | sed -E 's/80:(.*)\/TCP/\1/')
    curl 192.168.33.13:$(kubectl get services | grep webserver | awk '{print $5}' | sed -E 's/80:(.*)\/TCP/\1/')

#### Configure nfs mount for NFS Persistent Volume

https://linuxhint.com/install-and-configure-nfs-server-ubuntu-22-04/

    apt-get install -y nfs-kernel-server
    mkdir -p /mnt/nfs_share/pv1
    mkdir -p /mnt/nfs_share/pv2
    chmod ugo+rwx -R /mnt/nfs_share
    echo "/mnt/nfs_share 192.168.33.14/24(rw,sync,no_subtree_check)" >>/etc/exports
    exportfs -a
    systemctl restart nfs-kernel-server

#### Configure ingress

https://kubernetes.github.io/ingress-nginx/deploy/#quick-start

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
    kubectl get pods --namespace=ingress-nginx
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s

Local testing:

    kubectl create deployment demo --image=httpd --port=80
    kubectl expose deployment demo
    kubectl create ingress demo-localhost --class=nginx \
      --rule="demo.localdev.me/*=demo:80"
    kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80

At this point, if you access http://demo.localdev.me:8080/, you should see an HTML page telling you "It works!".

#### Create dashboard

Read more at https://github.com/kubernetes/dashboard

Install dashboard:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

To access Dashboard from your local workstation you must create a secure channel to your Kubernetes cluster. Run the following command:

    kubectl proxy

You can now access it from here

Read more at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

To have access to the cluster you need to create a service account and a cluster role binding.
Create a file named 

    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin-user
      namespace: kubernetes-dashboard
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin-user
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: admin-user
      namespace: kubernetes-dashboard

Get the token for the user:

    kubectl -n kubernetes-dashboard create token admin-user

Although not recommended in production you can access the dashboard from outside the cluster:

Read more at https://unixcop.com/how-to-access-kubernetes-dashboard-from-outside-cluster

    kubectl -n kube-system edit service kubernetes-dashboard

Change type of service From ClusteringIp NodePort

## Usage

### Configuration samples

#### Deployment sample

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.15.11
            ports:
            - containerPort: 80
#### Pod sample

    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-pod
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.15.11
        ports:
        - containerPort: 80

### Kubectl commands

#### Get details about Pods, replicationSets, Deployments

    kubectl get deploy,rs,po,service

#### Create deployment

    kubectl create deployment mynginx --image=nginx:1.15-alpine
    
or using file  

    kubectl create -f webserver.yaml

#### Get details based on label

    kubectl get deploy,rs,po -l app=mynginx
    
#### Get details with additional labels

    kubectl get po,rs,deployment -L k8s-app,label2
    
#### Scale deployment

    kubectl scale deploy mynginx --replicas=3

#### Describe deployment

    kubectl describe deploy mynginx 

#### Rollout history

    kubectl rollout history deployment mynginx
    kubectl rollout history deployment mynginx --revision=1
    for i in $(kubectl rollout history deployment mynginx | awk '{print $1}' | grep -v REVISION | grep -v deployment); do kubectl rollout history deployment mynginx --revision=$i; done

#### Update image name/version

    kubectl set image deployment mynginx nginx=nginx:1.16-alpine

This will create a new replica set revision.

#### Rollback to previous revision

    kubectl rollout undo deployment mynginx --to-revision=1
    
#### Expose service

    kubectl expose deployment webserver --name=web-service --type=NodePort

To open in browser

    minikube service web-service
    
#### Delete deployment

    vkubectl delete deployments mynginx

#### Logs

     kubectl logs readyness-exec
Flags
- -f - steam logs
- -p - logs for last restart
- -c - container name for multi container podk

### RBAC

TODO: WIP...

## Example

###