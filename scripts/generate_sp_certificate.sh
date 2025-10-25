#!/usr/bin/env bash

# Generate certificate for Azure Service Principal authentication
# This creates a self-signed certificate valid for 2 years

set -e

CERT_NAME="${1:-azure-sp-cert}"
VALIDITY_MONTHS="${2:-24}"
OUTPUT_DIR="${3:-.certs}"

echo "🔐 Generating Service Principal Certificate"
echo "============================================"
echo "Certificate name: ${CERT_NAME}"
echo "Validity: ${VALIDITY_MONTHS} months"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Generate private key and certificate
openssl req -x509 -newkey rsa:4096 -sha256 -days $((VALIDITY_MONTHS * 30)) \
    -keyout "${OUTPUT_DIR}/${CERT_NAME}.key" \
    -out "${OUTPUT_DIR}/${CERT_NAME}.crt" \
    -subj "/CN=Azure-SP-Certificate" \
    -nodes

# Create PEM file (combined cert + key for Azure CLI)
cat "${OUTPUT_DIR}/${CERT_NAME}.crt" "${OUTPUT_DIR}/${CERT_NAME}.key" > "${OUTPUT_DIR}/${CERT_NAME}.pem"

# Set restrictive permissions
chmod 600 "${OUTPUT_DIR}/${CERT_NAME}.key"
chmod 600 "${OUTPUT_DIR}/${CERT_NAME}.pem"
chmod 644 "${OUTPUT_DIR}/${CERT_NAME}.crt"

echo ""
echo "✅ Certificate generated successfully!"
echo ""
echo "📁 Files created:"
echo "   - Private key: ${OUTPUT_DIR}/${CERT_NAME}.key"
echo "   - Certificate: ${OUTPUT_DIR}/${CERT_NAME}.crt"
echo "   - PEM (for Azure CLI): ${OUTPUT_DIR}/${CERT_NAME}.pem"
echo ""
echo "📅 Expiration date:"
openssl x509 -in "${OUTPUT_DIR}/${CERT_NAME}.crt" -noout -enddate
echo ""
