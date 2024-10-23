#!/bin/bash

# Function to base64 encode the PEM file
function one_line_pem() {
    echo "=================  Generating Connection Profile  ================"
    # Base64 encode the PEM content to avoid issues with special characters
    base64 -w 0 $1
}

# Function to escape the base64 string for sed
function escape_for_sed() {
    echo $1 | sed -e 's/[\/&]/\\&/g'
}

# Function to generate JSON CCP using sed
function json_ccp() {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    PP=$(escape_for_sed "$PP")
    CP=$(escape_for_sed "$CP")
    echo "PEER PEM (escaped): $PP"
    echo "CA PEM (escaped): $CP"
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${P1PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        templates/ccp-template.json
}

# Function to generate YAML CCP using sed
function yaml_ccp() {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    PP=$(escape_for_sed "$PP")
    CP=$(escape_for_sed "$CP")
    echo "PEER PEM (escaped): $PP"
    echo "CA PEM (escaped): $CP"
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${P1PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        templates/ccp-template.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

# Set variables for Org1
ORG=1
P0PORT=7051
P1PORT=8051
CAPORT=7054
PEERPEM=crypto-config/peerOrganizations/org1.bionic.com/tlsca/tlsca.org1.bionic.com-cert.pem
CAPEM=crypto-config/peerOrganizations/org1.bionic.com/ca/ca.org1.bionic.com-cert.pem

# Generate JSON and YAML connection profiles
echo "$(json_ccp $ORG $P0PORT $P1PORT $CAPORT $PEERPEM $CAPEM)" > connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $P1PORT $CAPORT $PEERPEM $CAPEM)" > connection-org1.yaml
