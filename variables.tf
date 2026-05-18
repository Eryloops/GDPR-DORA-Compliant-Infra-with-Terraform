# Project name used in resource naming
variable "project_name" {
  type        = string
  description = "Name of the compliance project."
  default     = "eu-compliance"
}

# Environment label for tagging (dev, staging, prod)
variable "environment" {
  type        = string
  description = "Enviroment name"
  default     = "dev"
}

# AWS region with validation to enforce EU-only deployments
variable "aws_region" {
  type        = string
  description = "AWS region - must be an EU region for GDPR compliance."
  default     = "eu-central-1"

  # Reject any region that is not in the EU
  validation {
    condition = contains([
      "eu-west-1",
      "eu-west-2",
      "eu-west-3",
      "eu-central-1",
      "eu-central-2",
      "eu-north-1",
      "eu-south-1",
      "eu-south-2",
    ], var.aws_region)
    error_message = "Region must be an Eu region for GDPR compliance."
  }
}
