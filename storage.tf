
# Creates an S3 bucket for GDPR-compliant data storage
resource "aws_s3_bucket" "gdpr_data" {
  bucket_prefix = "${var.project_name}-data-"
  force_destroy = true
}
# Enables versioning to satisfy GDPR data availability and protection requirements.
resource "aws_s3_bucket_versioning" "gdpr_data" {
  bucket = aws_s3_bucket.gdpr_data.id
  versioning_configuration {
    status = "Enabled"
  }
}
# Configures server-side encryption using the KMS key we created for GDPR data protection.
resource "aws_s3_bucket_server_side_encryption_configuration" "gdpr_data" {
  bucket = aws_s3_bucket.gdpr_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      # References the ARN of the key created in kms.tf
      kms_master_key_id = aws_kms_key.gdpr_data.arn
    }
    # Enabling bucket key reduces the cost of encryption by using a bucket-level key for multiple objects.
    bucket_key_enabled = true
  }
}
# Enforces strict public access settings to ensure GDPR compliance by preventing accidental data exposure.
resource "aws_s3_bucket_public_access_block" "gdpr_data" {
  bucket = aws_s3_bucket.gdpr_data.id

  # Blocks all public ACLs and ignore any existing one to secure individual objects.
  block_public_acls  = true
  ignore_public_acls = true

  # Prevents the bucket from being made public through policies.
  block_public_policy     = true
  restrict_public_buckets = true
}

# Enforces that all data transfers to and from the bucket use SSL, ensuring data in transit is protected.
resource "aws_s3_bucket_policy" "gdpr_data_ssl_only" {
  bucket = aws_s3_bucket.gdpr_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.gdpr_data.arn,
          "${aws_s3_bucket.gdpr_data.arn}/*"
        ]
        # If HTTPS is false (SecureTransport is false), access is instantly denied.
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
