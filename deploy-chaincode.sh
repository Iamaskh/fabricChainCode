#!/bin/bash

# Organization 1 will be the one to commit the chaincode

#package chaincode
bash fabric-network.sh package-cc fabcar golang 1 

#install chaincode 
bash fabric-network.sh install-cc fabcar

#query chaincode installation
bash fabric-network.sh query-installed-cc >&install-log.txt

PACKAGE_ID=$(cat install-log.txt | awk "/Package ID: /{print}" | sed -n 's/^Package ID: //; s/, Label:.*$//;p')

echo "Package id is: " $PACKAGE_ID
#approve chaincode
bash fabric-network.sh approve-cc channelall fabcar 1 $PACKAGE_ID 1 

#check commit readiness
bash fabric-network.sh checkcommitreadiness-cc channelall fabcar 1 1 json

#commit chaincode - only org1 will do it
bash fabric-network.sh commit-cc channelall fabcar 1 1 

#query committed code
bash fabric-network.sh query-committed-cc channelall

#initialize chaincode - only org1 will do it
bash fabric-network.sh init-cc channelall fabcar

