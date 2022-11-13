#!/bin/bash

vagrant plugin install vagrant-scp

bash createMaster.sh

bash createWorkers.sh

bash postCreate.sh

echo done