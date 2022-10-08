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


for i in worker-1,192.168.33.14 worker-2,192.168.33.15 worker-3,192.168.33.16 worker-4,192.168.33.17; do
  worker=${i%,*};
  ip=${i#*,};

  vagrant up $worker
  vagrant scp ~/.kube $worker:/home/vagrant/
  vagrant scp ~/kubeadm-join.sh $worker:/home/vagrant/
  vagrant ssh $worker -c "sudo bash kubeadm-join.sh"

  for i in pv1 pv2; do
    vagrant ssh $worker -c "sudo mkdir -p /mnt/nfs_pv/$i"
    vagrant ssh $worker -c "sudo chmod ugo+rwx /mnt/nfs_pv/$i"
    vagrant ssh $worker -c "sudo chown -R nobody:nogroup /mnt/nfs_pv/$i"
    vagrant ssh $worker -c "echo \"/mnt/nfs_pv/$i $ip/24(rw,sync,no_subtree_check)\" | sudo tee -a /etc/exports"
  done
  vagrant ssh $worker -c "sudo exportfs -a"
  vagrant ssh $worker -c "sudo systemctl restart nfs-kernel-server"
done

echo done;