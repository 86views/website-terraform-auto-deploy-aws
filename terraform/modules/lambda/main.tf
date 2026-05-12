data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.module}/dist/${var.function_name}.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  tags = {
    Name        = var.function_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── Lambda Execution Role ────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"   # ✅ removed environment suffix — stable name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.function_name}-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ─── Optional DynamoDB Access ─────────────────────────────────────────────────
resource "aws_iam_role_policy" "dynamodb_access" {
  count = var.enable_dynamodb_access ? 1 : 0
  name  = "${var.function_name}-dynamodb-policy"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = var.dynamodb_table_arn
    }]
  })
}

# ─── Optional SES Access (contact form) ──────────────────────────────────────
resource "aws_iam_role_policy" "ses_access" {
  count = var.enable_ses_access ? 1 : 0
  name  = "${var.function_name}-ses-policy"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      Resource = "*"
    }]
  })
}