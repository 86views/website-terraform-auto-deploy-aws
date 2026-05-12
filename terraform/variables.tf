variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name — used for tagging only, not resource naming"
  type        = string
  default     = "static-website"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "prod"
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo (e.g. myorg/myrepo)"
  type        = string
  # ✅ no default — must be passed explicitly
}

variable "contact_email" {
  description = "Email address for contact form notifications"
  type        = string
  sensitive   = true
  # ✅ no default — must be passed explicitly
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for monitoring alerts (leave empty to disable)"
  type        = string
  sensitive   = true
  default     = ""    # ✅ empty string — consistent with count check in main.tf
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}

# ─── Optional / Future Use ────────────────────────────────────────────────────
variable "domain_name" {
  description = "Custom domain name (optional — leave null to use CloudFront default)"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (required if domain_name is set)"
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (required if domain_name is set)"
  type        = string
  default     = null
}