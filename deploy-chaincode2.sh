#!/bin/bash

# Organization 2 will approve the chaincode 

./fabric-network.sh package-cc fabcar golang 1

#install chaincode
./fabric-network.sh install-cc fabcar

#query chaincode installation
./fabric-network.sh query-installed-cc >&install-log.txt

PACKAGE_ID=$(cat install-log.txt | awk "/Package ID: /{print}" | sed -n 's/^Package ID: //; s/, Label:.*$//;p')

echo "Package id is: " $PACKAGE_ID
#approve chaincode
./fabric-network.sh approve-cc channelall fabcar 1 $PACKAGE_ID 1 


#query committed code
./fabric-network.sh query-committed-cc channelall 
