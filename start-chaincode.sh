#!/bin/bash

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/config/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/config/
export CHANNEL_NAME=mychannel

setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/config/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp
}

setGlobalsForPeer0Org1() {
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/config/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

presetup() {
    echo "Vendoring Go dependencies..."
    pushd ./chaincode
    GO111MODULE=on go mod tidy
    popd
    echo "Finished vendoring Go dependencies."
}

# Chaincode specifications
CHANNEL_NAME="bionicchannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
SEQUENCE=1
CC_SRC_PATH="./chaincode"
CC_NAME="example"

packageChaincode() {
    echo "Packaging chaincode..."
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0Org1
    peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged ====================="
}

installChaincode() {
    echo "Installing chaincode on peers..."
    setGlobalsForPeer0Org1
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode installed on peer0.org1 ====================="
}

queryInstalled() {
    setGlobalsForPeer0Org1
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo "PackageID is ${PACKAGE_ID}"
    echo "===================== Query installed successful on peer0.org1 ====================="
}

approveForMyOrg() {
    local org=$1
    local peer=$2
    local address=$3
    local tlsRootCertFile=$4

    setGlobalsFor${org}
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.example.com --tls \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --version ${VERSION} --init-required --package-id ${PACKAGE_ID} \
        --sequence ${SEQUENCE}

    echo "===================== Chaincode approved from ${org} ====================="
}

checkCommitReadyness() {
    local org=$1
    setGlobalsFor${org}
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:${PEER_PORT} --tlsRootCertFiles ${tlsRootCertFile} \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required
    echo "===================== Checking commit readiness from ${org} ====================="
}

commitChaincodeDefinition() {
    echo "Committing chaincode definition..."
    setGlobalsForPeer0Org1
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
        --version ${VERSION} --sequence ${SEQUENCE} --init-required
    echo "===================== Chaincode definition committed ====================="
}

queryCommitted() {
    setGlobalsForPeer0Org1
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}
}

chaincodeInvokeInit() {
    setGlobalsForPeer0Org1
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
        --isInit -c '{"Args":[]}'

    echo "===================== Chaincode initialization invoked ====================="
}

# Main execution flow
# presetup
# packageChaincode
installChaincode
# queryInstalled

# # Approve for all organizations
# approveForMyOrg "Org1" "peer0.org1.example.com" "localhost:7051" "$PEER0_ORG1_CA"

# # Check commit readiness for all organizations
# checkCommitReadyness "Org1"

# commitChaincodeDefinition
# queryCommitted
# chaincodeInvokeInit

# # Optional: Uncomment for additional invocations
# # chaincodeInvoke
# # chaincodeQuery

# echo "===================== Chaincode deployment complete ====================="
