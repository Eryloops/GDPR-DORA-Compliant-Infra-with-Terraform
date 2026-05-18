
# IAM POLICY: Enforces the EU data boundary by blocking resource creation anywhere else.
resource "aws_iam_policy" "eu_region_restriction" {
  name        = "${var.project_name}-eu-region-only"
  description = "Deny resource creation outside EU regions - DORA compliance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyNonEURegions"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance",
          "s3:CreateBucket",
          "dynamodb:CreateTable",
          "lambda:CreateFunction"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "eu-west-1",
              "eu-west-2",
              "eu-west-3",
              "eu-central-1",
              "eu-central-2",
              "eu-north-1",
              "eu-south-1",
              "eu-south-2"
            ]
          }
        }
      }
    ]
  })
}
