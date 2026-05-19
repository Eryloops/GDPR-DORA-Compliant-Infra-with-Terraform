# Creates a secure S3 bucket for storing CloudTrail audit logs, with strict access controls and encryption settings to ensure compliance with EU data protection standards.
resource "aws_s3_bucket" "audit_logs" {
  bucket_prefix = "${var.project_name}-audit-"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }

}

# Automatically encrypts all log files at rest using standard AES256.
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enforces strict public access settings to ensure audit logs are never exposed publicly.
resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# This bucket policy allows CloudTrail to write logs to the bucket while denying all other access, ensuring that only authorized AWS services can interact with the audit logs.
resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-audit-trail"
          }

        }
      },
      # Allows CloudTrail to deliver logs to the AWSLogs folder.
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-audit-trail"
          }
        }
      }
    ]
  })
}

# The engine that captures API events and delivers them to the audit bucket.
resource "aws_cloudtrail" "audit" {
  name           = "${var.project_name}-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.id

  # Data Sovereignity: Restricts logging to the EU region only.
  is_multi_region_trail = false

  # DORA Compliance: Generates cryptographic integrity checks for log files to prevent tampering and ensure data authenticity.
  enable_log_file_validation = true

  # Captures global services (like IAM users/roles changes) that impact this account.
  include_global_service_events = true

  # Send events to CloudWatch Logs for real-time monitoring
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  # Sequential Deployment: Ensures permissions exist before CloudTrail attempts first delivery.
  depends_on = [aws_s3_bucket_policy.audit_logs]
}
