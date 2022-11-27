PS: Don't hesitate  give a star ⭐ :heart: :star: 

# k8s-cluster

spin up five node cluster

* 192.168.33.13 master
* 192.168.33.14 worker-1
* 192.168.33.15 worker-2
* 192.168.33.16 worker-3
* 192.168.33.17 worker-4

see the corresponding post from [here](https://baykara.medium.com/setup-own-kubernetes-cluster-via-virtualbox-99a82605bfcc)

# requirements
```
vagrant
virtualbox
```

# Fire up vms

``` 
bash createCluster.sh
```

The script will do 3 things:

1. create masters and configure network using an addon like Antrea
2. create workers and make them join the master
3. do additional configuration like creating an ingress controller

# Accessing machines

To access each machine respectively via 

```
vagrant ssh master
vagrant ssh worker-1
```
