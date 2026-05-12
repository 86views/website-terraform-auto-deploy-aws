variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for OAC access"
  type        = string
}