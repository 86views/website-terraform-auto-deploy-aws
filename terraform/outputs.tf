output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value = format(
    "https://%s.execute-api.%s.amazonaws.com/%s",
    aws_api_gateway_rest_api.static_api.id,
    var.aws_region,
    aws_api_gateway_stage.static_api_stage.stage_name
  )
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
  description = "S3 website bucket name"
  value       = module.s3_website.bucket_name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "visitor_counter_table" {
  description = "DynamoDB visitor counter table name"
  value       = aws_dynamodb_table.visitor_counter.name
}

# ✅ Add this — useful for GitHub Actions workflow secret reference
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions — save this as STATICWEBSITE_GITHUB_ROLE_ARN secret"
  value       = module.iam.github_actions_role_arn
}