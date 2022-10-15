#!/bin/bash

vagrant plugin install vagrant-scp

bash createMaster.sh

bash createWorkers.sh

echo done;