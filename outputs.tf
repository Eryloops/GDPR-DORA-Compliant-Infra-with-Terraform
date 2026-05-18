# OUTPUTS: Defines the outputs for the GDPR-compliant infrastructure, providing essential information about the created resources such as bucket names, KMS key ARN, and CloudTrail ARN for easy reference and integration with other systems or documentation. 

# Defines the output for the GDPR-compliant data bucket name, allowing other modules or users to easily reference this bucket in their configurations or documentation.
output "gdpr_data_bucket_name" {
  description = "Name of the GDPR-compliant data bucket"
  value       = aws_s3_bucket.gdpr_data.id
}

# Displays the final name of the audit logs bucket.
output "audit_logs_bucket_name" {
  description = "Name of the audit logs bucket"
  value       = aws_s3_bucket.audit_logs.id
}

# Displays the ARN of the KMS key used for encrypting GDPR data.
output "kms_key_arn" {
  description = "ARN of the GDPR data encryption key"
  value       = aws_kms_key.gdpr_data.arn
}

# Displays the ARN of the CloudTrail audit trail, which is essential for monitoring and compliance reporting.
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail audit trail"
  value       = aws_cloudtrail.audit.arn
}

# Provides the ARN of the IAM policy that enforces EU region restrictions.
output "region_restriction_policy_arn" {
  description = "ARN of the EU region restriction policy"
  value       = aws_iam_policy.eu_region_restriction.arn
}

# Compliance notice regarding the limitations of AWS's data protection under the CLOUD Act, especially when using KMS for encryption, which is crucial for users to understand the implications of their data sovereignty choices.
output "cloud_act_risk_notice" {
  description = "CLOUD Act compliance notice"
  value       = "WARNING: AWS is US-incorporated. Data encrypted with SSE-C (client-side keys) is protected. Data encrypted with KMS only has reduced protection under CLOUD Act. For SEAL-3+ sovereignty, use EU-native providers."
}
