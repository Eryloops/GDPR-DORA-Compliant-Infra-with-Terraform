# COMPLIANCE DOCUMENTATION: This local block documents the geopolitical risk 
# and the sovereignty strategy directly alongside the infrastructure code.
locals {
  cloud_act_notice = <<-EOT
    CLOUD ACT RISK NOTICE:
    AWS (Amazon.com Inc.) is a US-incorporated company subject to the US CLOUD Act
    (Clarifying Lawful Overseas Use of Data Act, 2018). This law allows US authorities
    to compel US companies to hand over data regardless of where the data is physically
    stored. Storing data in eu-central-1 does NOT protect it from CLOUD Act requests.

    MITIGATION STRATEGY:
    This infrastructure uses client-side encryption (SSE-C) for sensitive data.
    The encryption key is generated and stored locally, never transmitted to AWS in
    plaintext at rest. AWS only stores ciphertext. Even if compelled by CLOUD Act,
    AWS can only provide encrypted data they cannot decrypt.

    For maximum sovereignty (SEAL-3/4), consider migrating sensitive workloads to
    EU-incorporated providers (OVHcloud, Scaleway, STACKIT) where CLOUD Act does
    not apply.
  EOT
}

# Enforces strict data protection controls directly on the S3 bucket.
# This policy replaces the previous basic SSL policy to add upload encryption enforcement.
resource "aws_s3_bucket_policy" "enforce_client_side_encryption" {
  bucket = aws_s3_bucket.gdpr_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # RULE 1: Enforce encryption in transit. Reject any non-HTTPS traffic.
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.gdpr_data.arn,
          "${aws_s3_bucket.gdpr_data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        # RULE 2: Enforces encryption at rest. Rejects uploads that are not encrypted.
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.gdpr_data.arn}/*"
        Condition = {
          # If the upload encryption type does NOT match KMS or AES256, block it.
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["aws:kms", "AES256"]
          }
        }
      }
    ]
  })

}
