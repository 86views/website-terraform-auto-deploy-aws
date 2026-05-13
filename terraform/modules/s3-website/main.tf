resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform" 
  }
}

# ----------------------------
# Public access MUST be blocked (secure setup)
# ----------------------------
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------
# Versioning (safe + useful for rollback)
# ----------------------------
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ----------------------------
# CloudFront OAC Policy (SECURE ACCESS ONLY)
# ----------------------------
data "aws_iam_policy_document" "website" {

  statement {
    sid     = "AllowCloudFrontAccess"
    effect  = "Allow"

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website.json

  depends_on = [aws_s3_bucket_public_access_block.website]
}