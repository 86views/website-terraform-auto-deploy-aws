# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"
}

# Slack Notifier Lambda
module "lambda_slack_notifier" {
  source = "../lambda"

  function_name = "${var.project_name}-slack-notifier-${var.environment}"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_path   = "${path.root}/lambda-functions/slack-notifier"

  environment_variables = {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  }
}

# SNS Subscription
resource "aws_sns_topic_subscription" "slack_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = module.lambda_slack_notifier.function_arn
}

# Lambda Permission
resource "aws_lambda_permission" "sns_invoke_slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# API Gateway Alarm
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${var.project_name}-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.environment
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Lambda Errors Alarm
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
}

# Lambda Throttles Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-lambda-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# CloudFront Alarm
resource "aws_cloudwatch_metric_alarm" "cloudfront_errors" {
  alarm_name          = "${var.project_name}-cloudfront-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}