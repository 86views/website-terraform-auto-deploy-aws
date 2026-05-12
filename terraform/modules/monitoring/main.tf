resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-alerts-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── Slack Notifier Lambda ────────────────────────────────────────────────────
module "lambda_slack_notifier" {
  source = "../lambda"

  function_name = var.slack_notifier_function_name    # ✅ stable name from root
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_path   = "${path.root}/lambda-functions/slack-notifier"
  environment   = var.environment

  environment_variables = {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  }
}

# ─── Allow SNS to invoke Lambda ───────────────────────────────────────────────
resource "aws_lambda_permission" "sns_invoke_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# ─── SNS → Lambda Subscription ───────────────────────────────────────────────
resource "aws_sns_topic_subscription" "slack_alerts" {
  topic_arn  = aws_sns_topic.alerts.arn
  protocol   = "lambda"
  endpoint   = module.lambda_slack_notifier.function_arn
  depends_on = [aws_lambda_permission.sns_invoke_slack]
}

# ─── Lambda Error Alarm ───────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.project_name}-lambda-errors-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── CloudFront 5xx Error Alarm ───────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cloudfront_errors" {
  alarm_name          = "${var.project_name}-cloudfront-5xx-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    DistributionId = var.cloudfront_distribution_id    # ✅ now actually used
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.project_name}-cloudfront-5xx-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}