#!/bin/bash

vagrant destroy -f master

vagrant up master

vagrant ssh master -c "sudo kubeadm init --apiserver-advertise-address 192.168.33.13 --pod-network-cidr=10.244.0.0/16 | tee kubeadm-init.txt"
vagrant ssh master -c "sudo chown \$(id -u):\$(id -g) \$HOME/kubeadm-init.txt"

vagrant ssh master -c "mkdir -p \$HOME/.kube"
vagrant ssh master -c "sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
vagrant ssh master -c "sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

vagrant ssh master -c "tail -n 2 kubeadm-init.txt >kubeadm-join.sh"
vagrant ssh master -c "kubectl apply -f https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/antrea.yml"

vagrant scp master:/home/vagrant/.kube ~
vagrant scp master:/home/vagrant/kubeadm-join.sh ~