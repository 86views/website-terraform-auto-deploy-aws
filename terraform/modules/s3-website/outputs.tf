output "bucket_id" {
  value = aws_s3_bucket.website.id
}

output "bucket_name" {
  value = aws_s3_bucket.website.id
}

output "bucket_arn" {
  value = aws_s3_bucket.website.arn
}

output "bucket_domain" {
  value = aws_s3_bucket.website.bucket_domain_name
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}