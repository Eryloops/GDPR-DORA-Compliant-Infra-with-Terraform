terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.2"
}

#Configure the AWS provider with EU region and compliance tags
provider "aws" {
  region = var.aws_region

  #These tags are automatically applied to every resource we create with compliance metadata
  default_tags {
    tags = {
      Compliance    = "GDPR-DORA"
      DataResidency = "EU"
      Environment   = "var.environment"
      ManagedBy     = "Terraform"
      Project       = "var.project_name"
    }
  }
}
