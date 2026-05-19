# CloudWatch Log Group for CloudTrail events
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 90
}

# IAM role that allows CloudTrail to write to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy granting CloudTrail permission to create log streams and put events
resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# Metric filter: detect unauthorized API calls in CloudTrail logs
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project_name}-unauthorized-calls"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "${var.project_name}/Security"
    value     = "1"
  }
}

# SNS topic for security alert notifications
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"
}

# Alarm: fires when any unauthorized API call is detected
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.project_name}-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "${var.project_name}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DORA: Detects unauthorized API calls indicating potential security incidents"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}
