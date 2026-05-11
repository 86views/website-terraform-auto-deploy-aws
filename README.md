# Static Website on AWS Free Tier (Terraform)

Modern, secure, and scalable static website using S3 + CloudFront + Lambda@Edge.

## Features
- S3 Static Hosting with OAC
- CloudFront CDN + HTTPS (ACM)
- Lambda@Edge:
  - Maintenance Mode
  - Visitor Counter (DynamoDB)
  - Contact Form (SES)
- GitHub Actions CI/CD
- Free Tier Optimized

## Quick Start
1. `cp terraform/terraform.tfvars.example terraform/terraform.tfvars`
2. Edit variables (especially domain and bucket name)
3. `cd terraform && terraform init && terraform apply`
4. Push `website/` folder (GitHub Actions will sync)

## Architecture
- S3 (origin) → CloudFront → Lambda@Edge