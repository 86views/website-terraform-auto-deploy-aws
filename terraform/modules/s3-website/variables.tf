variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = ""
}

variable "cloudfront_origin_access_identity_arn" {
  description = "CloudFront OAI ARN"
  type        = string
  default     = ""
}


variable "cloudfront_distribution_arn" {
  type = string
}