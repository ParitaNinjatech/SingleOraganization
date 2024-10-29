#!/bin/bash

# Set Environment Variables
function set_env() {
    export FABRIC_CFG_PATH="/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config"
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export CORE_PEER_ADDRESS=localhost:7051
    echo "Environment variables set."
}

# Verify Peer Version
function verify_peer_version() {
    peer version
}

# Package Chaincode
function package_chaincode() {
    peer lifecycle chaincode package basic.tar.gz --path ./chaincode/example/ --lang golang --label basic_1.0
    echo "Chaincode packaged."
}

# Install Chaincode
function install_chaincode() {
    peer lifecycle chaincode install basic.tar.gz
    echo "Chaincode installed."
}

# Query Installed Chaincode and Set Package ID Dynamically
function query_installed_chaincode() {
    PACKAGE_INFO=$(peer lifecycle chaincode queryinstalled | grep "basic_1.0")
    CC_PACKAGE_ID=$(echo $PACKAGE_INFO | awk -F ", " '{print $1}' | awk -F "Package ID: " '{print $2}' | awk -F " " '{print $1}')
    export CC_PACKAGE_ID
    echo "Chaincode package ID set: $CC_PACKAGE_ID"
}

# Approve Chaincode for Organization
function approve_chaincode() {
    echo "Chaincode package ID set: $CC_PACKAGE_ID"
    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID bionicchannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    echo "Chaincode approved for my org."
}

# Check Commit Readiness
function check_commit_readiness() {
    peer lifecycle chaincode checkcommitreadiness --channelID bionicchannel --name basic --version 1.0 --sequence 1 --tls --cafile "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --output json
}

# Commit Chaincode
function commit_chaincode() {
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID bionicchannel --name basic --version 1.0 --sequence 1 --tls --cafile "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    echo "Chaincode committed."
}

# Query Committed Chaincode
function query_committed_chaincode() {
    peer lifecycle chaincode querycommitted --channelID bionicchannel --name basic --cafile "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
}

# Invoke Chaincode Functions
function create_asset() {
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C bionicchannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c '{"function":"CreateAsset","Args":["asset1", "AssetName"]}'
}

function read_asset() {
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C bionicchannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "/home/ninjatech/Desktop/Hyperledger_Project/Sample-Fabric-2.5-single-org-single-peer-chaincode/sample/config/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" -c '{"function":"ReadAsset","Args":["asset1"]}'
}

# Query Chaincode
function query_chaincode() {
    peer chaincode query -C bionicchannel -n basic -c '{"Args":["ReadAsset","asset1"]}'
}

# Main Execution
set_env
verify_peer_version
package_chaincode
sleep 2
install_chaincode
sleep 2
query_installed_chaincode
sleep 2
approve_chaincode
sleep 2
check_commit_readiness
commit_chaincode
sleep 2
query_committed_chaincode
sleep 2
create_asset
sleep 2
read_asset
query_chaincode

echo "All commands executed."
