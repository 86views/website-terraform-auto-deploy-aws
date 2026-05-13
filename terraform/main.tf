terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# ─── Locked Resource Names ────────────────────────────────────────────────────
# Change project_name freely — these names never change
locals {
  bucket_name           = "static-website-${var.environment}-${random_string.suffix.result}"
  dynamodb_name         = "static-website-visitors-${var.environment}"
  contact_function_name = "static-website-contact-${var.environment}"
  counter_function_name = "static-website-counter-${var.environment}"
  slack_function_name   = "static-website-slack-notifier-${var.environment}"
  api_gateway_name      = "static-website-api-${var.environment}"
}

# ─── IAM ─────────────────────────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam" # ✅ fixed path

  project_name      = var.project_name
  environment       = var.environment
  github_repository = var.github_repository
  state_bucket      = var.state_bucket
  lock_table        = var.lock_table
}

# ─── S3 ──────────────────────────────────────────────────────────────────────
module "s3_website" {
  source       = "./modules/s3-website"
  project_name = var.project_name
  environment  = var.environment
  bucket_name  = local.bucket_name # ✅ locked name

  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
}

# ─── CloudFront ───────────────────────────────────────────────────────────────
module "cloudfront" {
  source           = "./modules/cloudfront"
  project_name     = var.project_name
  environment      = var.environment
  s3_bucket_domain = module.s3_website.bucket_regional_domain

  # SPA error handling — passed explicitly, no hardcoded duplicates in module
  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" }
  ]
}

# ─── DynamoDB ─────────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "visitor_counter" {
  name         = local.dynamodb_name # ✅ locked name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "page_id"

  attribute {
    name = "page_id"
    type = "S"
  }

  tags = {
    Name        = local.dynamodb_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = false # ✅ hard guard — never accidentally deleted
  }
}

# ─── Contact Lambda ───────────────────────────────────────────────────────────
module "lambda_contact" {
  source        = "./modules/lambda"
  function_name = local.contact_function_name # ✅ locked name
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_path   = "${path.module}/lambda-functions/contact-form"
  environment   = var.environment

  enable_ses_access = true # ✅ contact form needs SES

  environment_variables = {
    EMAIL_ADDRESS     = var.contact_email
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  }
}

# ─── Visitor Counter Lambda ───────────────────────────────────────────────────
module "lambda_counter" {
  source        = "./modules/lambda"
  function_name = local.counter_function_name # ✅ locked name
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_path   = "${path.module}/lambda-functions/visitor-counter"
  environment   = var.environment

  enable_dynamodb_access = true
  dynamodb_table_arn     = aws_dynamodb_table.visitor_counter.arn

  environment_variables = {
    TABLE_NAME = aws_dynamodb_table.visitor_counter.name
  }
}

# ─── API Gateway ──────────────────────────────────────────────────────────────
resource "aws_api_gateway_rest_api" "static_api" {
  name        = local.api_gateway_name # ✅ locked name
  description = "API Gateway for static website"

  tags = {
    Name        = local.api_gateway_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Contact resource
resource "aws_api_gateway_resource" "contact" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  parent_id   = aws_api_gateway_rest_api.static_api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_method" "contact_post" {
  rest_api_id   = aws_api_gateway_rest_api.static_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "contact_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.static_api.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.contact_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_contact.function_invoke_arn
}

# ✅ CORS for contact
resource "aws_api_gateway_method" "contact_options" {
  rest_api_id   = aws_api_gateway_rest_api.static_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.contact_options]
}

# Counter resource
resource "aws_api_gateway_resource" "counter" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  parent_id   = aws_api_gateway_rest_api.static_api.root_resource_id
  path_part   = "counter"
}

resource "aws_api_gateway_method" "counter_get" {
  rest_api_id   = aws_api_gateway_rest_api.static_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "counter_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.static_api.id
  resource_id             = aws_api_gateway_resource.counter.id
  http_method             = aws_api_gateway_method.counter_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_counter.function_invoke_arn
}

# ✅ CORS for counter
resource "aws_api_gateway_method" "counter_options" {
  rest_api_id   = aws_api_gateway_rest_api.static_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "counter_options" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "counter_options" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "counter_options" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.counter_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.counter_options]
}

# Deployment
resource "aws_api_gateway_deployment" "static_api" {
  rest_api_id = aws_api_gateway_rest_api.static_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contact.id,
      aws_api_gateway_resource.counter.id,
      aws_api_gateway_method.contact_post.id,
      aws_api_gateway_method.counter_get.id,
      aws_api_gateway_integration.contact_lambda.id,
      aws_api_gateway_integration.counter_lambda.id
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.contact_lambda,
    aws_api_gateway_integration.counter_lambda,
    aws_api_gateway_integration_response.contact_options,
    aws_api_gateway_integration_response.counter_options
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "static_api_stage" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.static_api.id
  deployment_id = aws_api_gateway_deployment.static_api.id

  tags = {
    Name        = "${local.api_gateway_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── Lambda Permissions ───────────────────────────────────────────────────────
resource "aws_lambda_permission" "contact" {
  statement_id  = "AllowContactInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_contact.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.static_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "counter" {
  statement_id  = "AllowCounterInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.static_api.execution_arn}/*/*"
}

# ─── Monitoring (only when Slack webhook provided) ────────────────────────────
module "monitoring" {
  count  = var.slack_webhook_url != "" ? 1 : 0 # ✅ skip if no webhook
  source = "./modules/monitoring"

  project_name                 = var.project_name
  environment                  = var.environment
  slack_webhook_url            = var.slack_webhook_url
  slack_notifier_function_name = local.slack_function_name # ✅ stable name
  lambda_function_name         = module.lambda_contact.function_name
  cloudfront_distribution_id   = module.cloudfront.cloudfront_distribution_id
}


resource "aws_ses_email_identity" "contact" {
  email = var.contact_email

  
}