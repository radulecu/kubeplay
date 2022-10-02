#!/bin/bash

vagrant plugin install vagrant-scp

vagrant destroy -f

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


vagrant up worker-1
vagrant scp ~/.kube worker-1:/home/vagrant/
vagrant scp ~/kubeadm-join.sh worker-1:/home/vagrant/
vagrant ssh worker-1 -c "sudo bash kubeadm-join.sh"

vagrant up worker-2
vagrant scp ~/.kube worker-2:/home/vagrant/
vagrant scp ~/kubeadm-join.sh worker-2:/home/vagrant/
vagrant ssh worker-2 -c "sudo bash kubeadm-join.sh"

vagrant up worker-3
vagrant scp ~/.kube worker-3:/home/vagrant/
vagrant scp ~/kubeadm-join.sh worker-3:/home/vagrant/
vagrant ssh worker-3 -c "sudo bash kubeadm-join.sh"

vagrant up worker-4
vagrant scp ~/.kube worker-4:/home/vagrant/
vagrant scp ~/kubeadm-join.sh worker-4:/home/vagrant/
vagrant ssh worker-4 -c "sudo bash kubeadm-join.sh"

echo done;