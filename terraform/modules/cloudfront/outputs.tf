output "cloudfront_domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.s3_distribution.arn
}

output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
}

output "origin_access_control_id" {
  value = aws_cloudfront_origin_access_control.oac.id
}