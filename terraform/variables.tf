variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "static-website"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "prod"
}

variable "github_repository" {
  description = "GitHub repository (format: owner/repo)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Custom domain name (optional)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 zone ID (required for custom domain)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (optional, for custom domain)"
  type        = string
  default     = ""
}

variable "contact_email" {
  description = "Email address for contact form submissions"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_webhook_url" {
  type      = string
  sensitive = true
  default   = ""     
}


variable "enable_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}