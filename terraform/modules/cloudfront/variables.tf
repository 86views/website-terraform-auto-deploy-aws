variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "s3_bucket_domain" {
  type        = string
  description = "S3 bucket regional domain name"
}

variable "custom_error_responses" {
  type = list(object({
    error_code         = number
    response_page_path = string
    response_code      = number
  }))
  default = [
    # ✅ SPA defaults here so root module doesn't have to set them
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" }
  ]
}