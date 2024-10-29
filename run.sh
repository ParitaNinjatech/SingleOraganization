#!/bin/bash

# Set FABRIC_CFG_PATH
export FABRIC_CFG_PATH=/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config

# Create network configuration
cryptogen generate --config=config/crypto-config.yaml

# Create orderer genesis block
configtxgen -profile OrdererGenesis -channelID bionic-sys-channel -outputBlock ./channel-artifacts/genesis.block --configPath=config/

# Create application channel
configtxgen -profile BasicChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID bionicchannel --configPath=config/

# Create Anchor peer configuration
configtxgen -profile BasicChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID bionicchannel -asOrg Org1MSP --configPath=config/

# Run docker-compose.yaml
docker-compose -f docker/docker-compose.yaml up -d

# Wait for services to start (optional)
sleep 5

# Run CLI service and execute commands inside the container
docker exec -it cli bash -c "
# Create the channel (using the working command)
peer channel create -o orderer.example.com:7050 -c bionicchannel -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Join peer to the channel
peer channel join -b bionicchannel.block

# Check available channels before update
peer channel list

# Update channel status
peer channel update -o orderer.example.com:7050 -c bionicchannel -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Check available channels after update
peer channel list
"