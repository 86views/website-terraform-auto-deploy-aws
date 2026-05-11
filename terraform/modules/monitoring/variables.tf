variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "slack_webhook_url" {
  type      = string
  sensitive = true
  default   = ""        # ← Add this — won't prompt if secret isn't set
}

variable "api_gateway_name" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "cloudfront_distribution_id" {
  type = string
}