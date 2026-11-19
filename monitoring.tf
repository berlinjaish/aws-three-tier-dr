# ==========================================
# MUMBAI PRIMARY - CLOUDWATCH MONITORING
# ==========================================

resource "aws_cloudwatch_metric_alarm" "primary_web_unhealthy_hosts" {
  provider = aws.primary

  alarm_name          = "three-tier-primary-web-unhealthy-hosts"
  alarm_description   = "Alert when one or more Mumbai web targets are unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions = [
    "arn:aws:sns:ap-south-1:357558450991:three-tier-primary-alerts"
  ]

  dimensions = {
    LoadBalancer = aws_lb.public.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  tags = {
    Project     = "aws-three-tier-dr"
    Environment = "dev"
    Region      = "primary"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "primary_app_unhealthy_hosts" {
  provider = aws.primary

  alarm_name          = "three-tier-primary-app-unhealthy-hosts"
  alarm_description   = "Alert when one or more Mumbai application targets are unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions = [
    "arn:aws:sns:ap-south-1:357558450991:three-tier-primary-alerts"
  ]

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  tags = {
    Project     = "aws-three-tier-dr"
    Environment = "dev"
    Region      = "primary"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "primary_rds_high_cpu" {
  provider = aws.primary

  alarm_name          = "three-tier-primary-rds-high-cpu"
  alarm_description   = "Alert when Mumbai primary RDS CPU is at least 80 percent"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions = [
    "arn:aws:sns:ap-south-1:357558450991:three-tier-primary-alerts"
  ]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = {
    Project     = "aws-three-tier-dr"
    Environment = "dev"
    Region      = "primary"
    ManagedBy   = "Terraform"
  }
}

# ==========================================
# MUMBAI PRIMARY - RDS LOW STORAGE ALARM
# ==========================================

resource "aws_cloudwatch_metric_alarm" "primary_rds_low_storage" {
  provider = aws.primary

  alarm_name          = "three-tier-primary-rds-low-storage"
  alarm_description   = "Alert when Mumbai primary RDS free storage falls below 2 GiB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2147483648
  comparison_operator = "LessThanOrEqualToThreshold"
  alarm_actions = [
    "arn:aws:sns:ap-south-1:357558450991:three-tier-primary-alerts"
  ]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }

  tags = {
    Project     = "aws-three-tier-dr"
    Environment = "dev"
    Region      = "primary"
    ManagedBy   = "Terraform"
  }
}


