variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "slack_webhook_url" {
  type      = string
  sensitive = true
  default   = ""        # ✅ never blocks pipeline
}

variable "slack_notifier_function_name" {
  type        = string
  description = "Stable name for the Slack notifier Lambda — set in root main.tf"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name to monitor for errors"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "CloudFront distribution ID for 5xx alarm"
}