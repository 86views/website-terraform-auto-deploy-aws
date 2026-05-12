variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "runtime" {
  type    = string
  default = "nodejs18.x"
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "source_path" {
  type        = string
  description = "Path to Lambda source code directory"
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "timeout" {
  type    = number
  default = 10
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN (required if enable_dynamodb_access = true)"
  type        = string
  default     = null
}

variable "enable_dynamodb_access" {
  description = "Enable DynamoDB permissions for this Lambda"
  type        = bool
  default     = false
}

variable "enable_ses_access" {
  description = "Enable SES permissions for this Lambda (contact form)"  # ✅ new
  type        = bool
  default     = false
}