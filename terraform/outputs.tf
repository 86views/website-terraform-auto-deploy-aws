output "api_gateway_url" {
  description = "API Gateway URL"

  value = "https://${aws_api_gateway_rest_api.static_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.static_api_stage.stage_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain" {
  description = "CloudFront domain name"
  value       = module.cloudfront.cloudfront_domain
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3_website.bucket_name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "static_website_github_role_arn" {
  description = "GitHub Actions IAM Role ARN"
  value       = var.github_repository != "" ? aws_iam_role.github_actions_role[0].arn : "GitHub OIDC not configured (github_repository variable not set)"
}


output "visitor_counter_table" {
  description = "DynamoDB table for visitor counter"
  value       = aws_dynamodb_table.visitor_counter.name
}