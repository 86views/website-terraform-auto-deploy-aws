variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (e.g. prod, dev)"
  type        = string
}

variable "github_repository" {
  description = "GitHub repo in format owner/repo (e.g. myorg/myrepo)"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket name used for Terraform state"
  type        = string
}

variable "lock_table" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
}


