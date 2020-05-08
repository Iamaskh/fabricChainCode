## Environment variables for future changes in names 
  export Org_Name=Org1
  export Org_MSP=Org1MSP
  export COMPOSE_PROJECT_NAME=net
  export NETWORK_NAME=fabric-template-network
  export IMAGE_TAG=latest
  export SYS_CHANNEL=byfn-sys-channel
  echo ${Org_Name}
if [ "$1" == "help" ]; then
  echo "Welcome to Fabric setup utility"
  echo "The command works like this:"
  echo "./fabric-network.sh COMMAND_NAME ARGS" 
  echo ""
  echo "1. To generate crypto material for this organization use:"
  echo " ./fabric-network.sh generate-crypto"
  echo ""
  echo "2. To bring up the organization:"
  echo " ./fabric-network.sh up"
  echo ""
  echo "3. To add config of another organization:"
  echo " ./fabric-network.sh add-org-config CHANNEL_NAME ORG_TO_BE_ADDED_NAME"
  echo ""
  echo "4. To sign config of another organization:"
  echo " ./fabric-network.sh add-org-sign CHANNEL_NAME ORG_TO_BE_SIGNED_NAME"
  echo ""
  echo "5. To join a channel:"
  echo " ./fabric-network.sh join-channel PEER_NAME CHANNEL_NAME"
  echo ""
  echo "6. To add another peer:"
  echo "./fabric-network.sh add-peer"
  echo ""
  echo "7. To package a chaincode:"
  echo " ./fabric-network.sh package-cc CHAINCODE_NAME CHAINCODE_LANGUAGE CHAINCODE_LABEL"
  echo ""
  echo "8. To install a chaincode:"
  echo " ./fabric-network.sh install-cc CHAINCODE_NAME"
  echo ""
  echo "9. To query whether a chaincode has installed:"
  echo " ./fabric-network.sh query-installed-cc"
  echo ""
  echo "10. To approve a chaincode from your organization:"
  echo " ./fabric-network.sh approve-cc CHANNEL_NAME CHAINCODE_NAME VERSION PACKAGE_ID SEQUENCE"
  echo ""
  echo "11. To check commit-readiness of a chaincode:"
  echo " ./fabric-network.sh checkcommitreadiness-cc CHANNEL_NAME CHAINCODE_NAME VERSION SEQUENCE OUTPUT"
  echo ""
  echo "12. To commit a chaincode:"
  echo " ./fabric-network.sh commit-cc CHANNEL_NAME CHAINCODE_NAME VERSION SEQUENCE"
  echo ""
  echo "13. To query committed chaincodes on a channel:"
  echo " ./fabric-network.sh query-committed-cc CHANNEL_NAME"
  echo ""
  echo "14. To initialize a chaincode:"
  echo " ./fabric-network.sh init-cc CHANNEL_NAME CHAINCODE_NAME"
  echo ""
  echo "15. To invoke a chaincode:"
  echo " ./fabric-network.sh invoke-function-cc CHANNEL_NAME CHAINCODE_NAME FUNCTION ARGS"
  echo ""
  echo "16. To query a chaincode:"
  echo " ./fabric-network.sh query-function-cc CHANNEL_NAME CHAINCODE_NAME ARGS"
  echo ""
  echo "17. To display help:"
  echo " ./fabric-network.sh help"
  echo ""
  echo "18. To shut down the organization and cleanup:"
  echo " ./fabric-network.sh down cleanup"
  echo ""
fi


if [ "$1" == "generate-crypto" ]; then
  rm -rf channel-artifacts/ crypto-config/
  ../bin/cryptogen generate --config=./crypto-config.yaml
  mkdir channel-artifacts && export FABRIC_CFG_PATH=$PWD
  ../bin/configtxgen -profile OrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
  echo "The required certificates have been generated and exported in channel-artifacts and crypto-config folders"
fi

if [ "$1" == "up" ]; then
  export FABRIC_CFG_PATH=$PWD
  export BYFN_CA1_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/${Org_Name,,}.example.com/ca && ls *_sk && cd ../../../../)
  echo $BYFN_CA1_PRIVATE_KEY
  docker network create $NETWORK_NAME
  docker-compose up -d
fi

if [ "$1" == "add-org-config" ]; then
  export CHANNEL_NAME="$2"
  export NEW_ORG="$3"
docker exec cli.${Org_Name,,}.example.com bash -c "scripts/add-org-config.sh $CHANNEL_NAME $NEW_ORG"
fi

if [ "$1" == "add-org-sign" ]; then
  export CHANNEL_NAME="$2"
  export NEW_ORG="$3"
docker exec cli.${Org_Name,,}.example.com bash -c "scripts/add-org-sign.sh $CHANNEL_NAME $NEW_ORG"
fi

if [ "$1" == "create-channel" ]; then
 export FABRIC_CFG_PATH=$PWD
  export CHANNEL_PROFILE="$2"
  export CHANNEL_NAME="$3"
  ../bin/configtxgen -profile ${CHANNEL_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
  ../bin/configtxgen -profile ${CHANNEL_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/${Org_Name}MSPanchors_${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME -asOrg ${Org_Name}MSP
  docker exec cli.${Org_Name,,}.example.com bash -c "scripts/create-channel.sh $CHANNEL_NAME $Org_Name"
fi

if [ "$1" == "join-channel" ]; then
  export PEER_NO="$2"
  export CHANNEL_NAME="$3"
  docker exec cli.${Org_Name,,}.example.com bash -c "scripts/join-channel.sh $CHANNEL_NAME ${Org_Name,,} $Org_MSP $PEER_NO"
fi

if [ "$1" == "add-peer" ]; then
  ../bin/cryptogen extend --config=./crypto-config.yaml
  docker-compose -f docker-compose-new-peer.yaml up -d
fi

if [ "$1" == "package-cc" ]; then
  export CHAINCODE_NAME="$2"
  export LANG="$3"
  export LABEL="$4"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path /opt/gopath/src/github.com/chaincode/go --lang $LANG --label $LABEL"
fi


if [ "$1" == "install-cc" ]; then
  export CHAINCODE_NAME="$2"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz"
fi

if [ "$1" == "query-installed-cc" ]; then
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode queryinstalled"
fi

if [ "$1" == "approve-cc" ]; then
  export CHANNEL_ID="$2"
  export CHAINCODE_NAME="$3"
  export VERSION="$4"
  export PACKAGE_ID="$5"
  export SEQUENCE="$6"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version $VERSION --init-required --package-id $PACKAGE_ID --waitForEvent --sequence $SEQUENCE"
fi

if [ "$1" == "checkcommitreadiness-cc" ]; then
  export CHANNEL_ID="$2"
  export CHAINCODE_NAME="$3"
  export VERSION="$4"
  export SEQUENCE="$5"
  export OUTPUT="$6"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version $VERSION --sequence $SEQUENCE --output $OUTPUT --init-required"
fi


if [ "$1" == "commit-cc" ]; then
  export CHANNEL_ID="$2"
  export CHAINCODE_NAME="$3"
  export VERSION="$4"
  export SEQUENCE="$5"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode commit -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID $CHANNEL_ID --name $CHAINCODE_NAME $PEER_CONN_PARMS --version $VERSION --sequence $SEQUENCE --init-required --peerAddresses peer0.${Org_Name,,}.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${Org_Name,,}.example.com/peers/peer0.${Org_Name,,}.example.com/tls/ca.crt"
fi

if [ "$1" == "query-committed-cc" ]; then
  export CHANNEL_ID="$2"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer lifecycle chaincode querycommitted --channelID $CHANNEL_ID"
fi

if [ "$1" == "init-cc" ]; then
  export CHANNEL_ID="$2"
  export CHAINCODE_NAME="$3"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --ordererTLSHostnameOverride orderer.example.com -C $CHANNEL_ID -n $CHAINCODE_NAME --isInit -c '{\"Args\":[]}' --peerAddresses peer0.${Org_Name,,}.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${Org_Name,,}.example.com/peers/peer0.${Org_Name,,}.example.com/tls/ca.crt"
fi

if [ "$1" == "invoke-function-cc" ]; then
  export CHANNEL_ID="$2"
  export CHAINCODE_NAME="$3"
  export FUNCTION_NAME="$4"
  export ARGS="$5"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --ordererTLSHostnameOverride orderer.example.com -C $CHANNEL_ID -n $CHAINCODE_NAME -c '{\"function\":\"'${FUNCTION_NAME}'\",\"Args\":[${ARGS}]}' --peerAddresses peer0.${Org_Name,,}.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${Org_Name,,}.example.com/peers/peer0.${Org_Name,,}.example.com/tls/ca.crt"
fi

if [ "$1" == "query-function-cc" ]; then
  export CHANNEL_ID="$2"
  export CHAINCODE_NAME="$3"
  export ARGS="$4"
  docker exec cli.${Org_Name,,}.example.com bash -c "peer chaincode query -C $CHANNEL_ID -n $CHAINCODE_NAME -c '{\"Args\":[\"${ARGS}\"]}'"
fi

if [ "$1" == "down" ]; then
  docker-compose down -v
  docker-compose -f docker-compose-new-peer.yaml down -v
 	if [ "$2" == "cleanup" ]; then
		  rm -rf channel-artifacts/ crypto-config/
	fi
fi
#end of file
