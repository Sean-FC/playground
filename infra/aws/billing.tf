locals {
  billing = {
    name        = join(module.context.delimiter, [module.context.id, "allowance", "exceeded"])
    maximum_usd = 50
  }
}

resource "aws_cloudwatch_metric_alarm" "allowance" {
  alarm_name          = local.billing.name
  alarm_description   = "Alerts if bill greater than expected for the month"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "28800"
  statistic           = "Maximum"
  threshold           = local.billing.maximum_usd
  alarm_actions       = [aws_sns_topic.allowance.arn]

  dimensions = {
    Currency = "USD"
  }
}

# Default delivery policy fine
resource "aws_sns_topic" "allowance" {
  name       = local.billing.name
  fifo_topic = false
}

# Per SMS cost: $0.00186
resource "aws_sns_topic_subscription" "allowance" {
  topic_arn = aws_sns_topic.allowance.arn
  protocol  = "sms"
  endpoint  = nonsensitive(local.secrets_main.personal.phone)
}
