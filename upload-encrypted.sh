#!/bin/bash
# CLOUD Act Mitigation: Client-Side Encryption Upload Script (BASH Version)
# This script encrypts data BEFORE sending it to AWS S3

# 1. Generate a 256-bit encryption key (32 random bytes encoded in Base64)
EncryptionKey=$(head -c 32 /dev/urandom | base64)

# Display the key
echo "Generated encryption key (KEEP THIS SAFE, NOT ON AWS):"
echo "$EncryptionKey"
echo ""

# 2. Calculate MD5 of the key for AWS SSE-C requirement
KeyBytes=$(echo -n "$EncryptionKey" | base64 --decode)
KeyMD5=$(echo -n "$KeyBytes" | openssl dgst -md5 -binary | base64)

# 3. Create a sample file with EU citizen data
echo -e "name: Juan Carlos Bodoque\nemail: bodoque@example.eu\nid: EU-CITIZEN-12345" > sample-gdpr-data.txt

# 4. Get the bucket name from Terraform output
BucketName=$(terraform output -raw gdpr_data_bucket_name)

# 5. Upload with client-side encryption (SSE-C)
aws s3api put-object \
    --bucket "$BucketName" \
    --key "gdpr-data/sample-gdpr-data.txt" \
    --body "sample-gdpr-data.txt" \
    --sse-customer-algorithm AES256 \
    --sse-customer-key "$EncryptionKey" \
    --sse-customer-key-md5 "$KeyMD5"

echo ""
echo "File uploaded with client-side encryption."
echo "AWS CANNOT decrypt this data - even under CLOUD Act compulsion."
echo ""
echo "To download and decrypt, you MUST provide the same key:"
echo "aws s3api get-object --bucket $BucketName --key gdpr-data/sample-gdpr-data.txt --sse-customer-algorithm AES256 --sse-customer-key $EncryptionKey --sse-customer-key-md5 $KeyMD5 downloaded.txt"

# 6. Clean up local sample file
rm sample-gdpr-data.txt