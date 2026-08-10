resource "aws_cloudwatch_metric_alarm" "security_metrics" {
  for_each = local.metric_filter_definitions

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.alarm_description
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = var.metric_namespace
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"

  alarm_actions             = local.effective_alarm_actions
  ok_actions                = local.effective_ok_actions
  insufficient_data_actions = local.effective_insufficient_data_actions

  tags = merge(local.common_tags, {
    AlarmType = each.key
    Severity  = each.value.severity
  })

  depends_on = [aws_cloudwatch_log_metric_filter.security]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  for_each = var.enable_ec2_usage_alarms ? local.ec2_instance_ids : toset([])

  alarm_name          = local.ec2_cpu_alarm_names[each.value]
  alarm_description   = "CPU utilization high for EC2 instance ${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.ec2_cpu_evaluation_periods
  datapoints_to_alarm = var.ec2_cpu_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.ec2_cpu_period
  statistic           = "Average"
  threshold           = var.ec2_cpu_threshold
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions             = local.effective_alarm_actions
  ok_actions                = local.effective_ok_actions
  insufficient_data_actions = local.effective_insufficient_data_actions

  tags = merge(local.common_tags, {
    AlarmType = "ec2_cpu"
    Severity  = "warning"
  })
}

resource "aws_cloudwatch_metric_alarm" "s3_bucket_size" {
  for_each = var.enable_s3_usage_alarms ? local.s3_bucket_names : toset([])

  alarm_name          = local.s3_size_alarm_names[each.value]
  alarm_description   = "S3 bucket size high for ${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.s3_bucket_size_evaluation_periods
  datapoints_to_alarm = var.s3_bucket_size_evaluation_periods
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = var.s3_bucket_size_period
  statistic           = "Average"
  threshold           = var.s3_bucket_size_threshold_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = each.value
    StorageType = "StandardStorage"
  }

  alarm_actions             = local.effective_alarm_actions
  ok_actions                = local.effective_ok_actions
  insufficient_data_actions = local.effective_insufficient_data_actions

  tags = merge(local.common_tags, {
    AlarmType = "s3_bucket_size"
    Severity  = "warning"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  for_each = var.enable_rds_usage_alarms ? local.rds_db_ids : toset([])

  alarm_name          = local.rds_cpu_alarm_names[each.value]
  alarm_description   = "CPU utilization high for RDS instance ${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.rds_cpu_evaluation_periods
  datapoints_to_alarm = var.rds_cpu_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.rds_cpu_period
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = each.value
  }

  alarm_actions             = local.effective_alarm_actions
  ok_actions                = local.effective_ok_actions
  insufficient_data_actions = local.effective_insufficient_data_actions

  tags = merge(local.common_tags, {
    AlarmType = "rds_cpu"
    Severity  = "warning"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  for_each = var.enable_rds_usage_alarms ? local.rds_db_ids : toset([])

  alarm_name          = local.rds_free_storage_alarm_names[each.value]
  alarm_description   = "Free storage space low for RDS instance ${each.value}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.rds_free_storage_evaluation_periods
  datapoints_to_alarm = var.rds_free_storage_evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = var.rds_free_storage_period
  statistic           = "Average"
  threshold           = var.rds_free_storage_threshold_bytes
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = each.value
  }

  alarm_actions             = local.effective_alarm_actions
  ok_actions                = local.effective_ok_actions
  insufficient_data_actions = local.effective_insufficient_data_actions

  tags = merge(local.common_tags, {
    AlarmType = "rds_free_storage"
    Severity  = "critical"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  for_each = var.enable_rds_usage_alarms ? local.rds_db_ids : toset([])

  alarm_name          = local.rds_connections_alarm_names[each.value]
  alarm_description   = "Database connections high for RDS instance ${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.rds_database_connections_evaluation_periods
  datapoints_to_alarm = var.rds_database_connections_evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = var.rds_database_connections_period
  statistic           = "Average"
  threshold           = var.rds_database_connections_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value
  }

  alarm_actions             = local.effective_alarm_actions
  ok_actions                = local.effective_ok_actions
  insufficient_data_actions = local.effective_insufficient_data_actions

  tags = merge(local.common_tags, {
    AlarmType = "rds_connections"
    Severity  = "warning"
  })
}
