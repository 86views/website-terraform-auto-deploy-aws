variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "s3_bucket_domain" {
  description = "S3 bucket domain"
  type        = string
}

variable "custom_error_responses" {
  description = "Custom error responses"
  type = list(object({
    error_code         = number
    response_page_path = string
    response_code      = number
  }))
  default = []
}

# These are kept for compatibility but not used in simplified version
variable "domain_name" {
  description = "Custom domain name (not used in simplified version)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 zone ID (not used in simplified version)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (not used in simplified version)"
  type        = string
  default     = ""
}