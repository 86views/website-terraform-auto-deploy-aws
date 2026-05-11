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

# --- Data Sources ---
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# --- GitHub OIDC Auth ---

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions_role" {
  count = var.github_repository != "" ? 1 : 0

  name = "${var.project_name}-github-actions-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"

      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }

      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
        }

        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_infrastructure" {
  count = var.github_repository != "" ? 1 : 0

  name = "infrastructure-management"
  role = aws_iam_role.github_actions_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:*",
          "cloudfront:*",
          "lambda:*",
          "apigateway:*",
          "dynamodb:*",
          "ses:*",
          "iam:GetRole",
          "iam:PassRole",
          "acm:*",
          "route53:*"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::tf-state-7afc2a05",
          "arn:aws:s3:::tf-state-7afc2a05/*"
        ]
      }
    ]
  })
}

# --- Application Modules ---
module "s3_website" {
  source       = "./modules/s3-website"
  project_name = var.project_name
  environment  = var.environment
  bucket_name  = "${var.project_name}-${var.environment}-${random_string.suffix.result}"
  domain_name  = var.domain_name
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
}

module "lambda_contact" {
  source        = "./modules/lambda"
  function_name = "${var.project_name}-contact-form-${var.environment}"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_path   = "${path.module}/lambda-functions/contact-form"
  environment_variables = {
    EMAIL_ADDRESS     = var.contact_email
    SLACK_WEBHOOK_URL = var.enable_slack_notifications ? var.slack_webhook_url : ""
  }
}



module "lambda_counter" {
  source                = "./modules/lambda"
  function_name         = "${var.project_name}-visitor-counter-${var.environment}"
  runtime               = "nodejs20.x"
  handler               = "index.handler"
  source_path           = "${path.module}/lambda-functions/visitor-counter"
  environment_variables = { TABLE_NAME = aws_dynamodb_table.visitor_counter.name }
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name               = var.project_name
  environment                = var.environment
  slack_webhook_url          = var.slack_webhook_url
  api_gateway_name           = aws_api_gateway_rest_api.static_api.name
  lambda_function_name       = module.lambda_contact.function_name
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
  # Only create Slack notifier if webhook URL is provided
   count = var.slack_webhook_url != "" ? 1 : 0
}

resource "aws_dynamodb_table" "visitor_counter" {
  name         = "${var.project_name}-visitors-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "page_id"
  attribute {
    name = "page_id"
    type = "S"
  }
}

module "cloudfront" {
  source           = "./modules/cloudfront"
  project_name     = var.project_name
  environment      = var.environment
  domain_name      = var.domain_name
  route53_zone_id  = var.route53_zone_id
  s3_bucket_id     = module.s3_website.bucket_id
  s3_bucket_arn    = module.s3_website.bucket_arn
  s3_bucket_domain = module.s3_website.bucket_domain

  custom_error_responses = [
    { error_code = 404, response_page_path = "/error.html", response_code = 404 },
    { error_code = 403, response_page_path = "/error.html", response_code = 404 }
  ]
}

# --- API Gateway Configuration ---
resource "aws_api_gateway_rest_api" "static_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "API Gateway for static website"
}

# Contact Endpoint
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

# Counter Endpoint
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

# Deployment & Stage (Unique Declarations)
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
    aws_api_gateway_integration.counter_lambda
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "static_api_stage" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.static_api.id
  deployment_id = aws_api_gateway_deployment.static_api.id
}

# --- Lambda Permissions ---
resource "aws_lambda_permission" "api_gateway_contact" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_contact.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.static_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_counter" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.static_api.execution_arn}/*/*"
}