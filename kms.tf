# Looks up current AWS Account ID dynamically.
data "aws_caller_identity" "current" {}

# Creates a customer-managed encryption key with automatic yearly rotation
resource "aws_kms_key" "gdpr_data" {
  description             = "Kms key for GDPR-compliant data encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  #Security policy: Defines who is allowed to manage and use this key.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}
#Creates a human-readable name for the AWS Console.
resource "aws_kms_alias" "gdpr_data" {
  name          = "alias/${var.project_name}-gdpr-key"
  target_key_id = aws_kms_key.gdpr_data.key_id
}
