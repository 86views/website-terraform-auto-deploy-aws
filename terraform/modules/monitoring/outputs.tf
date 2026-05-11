output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "slack_lambda_name" {
  value = module.lambda_slack_notifier.function_name
}