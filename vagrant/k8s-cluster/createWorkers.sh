#!/bin/bash

for i in \
    worker-1,192.168.56.14,eu-west-1,a \
    worker-2,192.168.56.15,eu-west-2,a \
    worker-3,192.168.56.16,eu-west-1,b \
    worker-4,192.168.56.17,eu-west-2,b \
    ;do

  array=($(echo $i | tr ',' "\n"))
  worker=${array[0]};
  ip=${array[1]};
  region=${array[2]};
  zone=$region${array[3]}

  vagrant destroy -f $worker

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

  kubectl label nodes $worker topology.kubernetes.io/region=$region
  kubectl label nodes $worker topology.kubernetes.io/zone=$zone
done