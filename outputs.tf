output "name_prefix" {
  description = "Shared naming prefix applied to resources created by this stack."
  value       = local.name_prefix
}

output "account_id" {
  description = "AWS account ID resolved from the current credentials."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region resolved from the provider."
  value       = data.aws_region.current.region
}

output "eventbridge_rule_arns" {
  description = "Map of EventBridge security rule key to rule ARN."
  value       = { for k, rule in aws_cloudwatch_event_rule.security : k => rule.arn }
}

output "eventbridge_rule_names" {
  description = "Map of EventBridge security rule key to rule name."
  value       = { for k, rule in aws_cloudwatch_event_rule.security : k => rule.name }
}

output "metric_filter_names" {
  description = "Map of metric filter key to filter name."
  value       = { for k, filter in aws_cloudwatch_log_metric_filter.security : k => filter.name }
}

output "cloudwatch_alarm_arns" {
  description = "Flat list of ARNs for all CloudWatch alarms created by this stack."
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.security_metrics : alarm.arn],
    [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu : alarm.arn],
    [for alarm in aws_cloudwatch_metric_alarm.s3_bucket_size : alarm.arn],
    [for alarm in aws_cloudwatch_metric_alarm.rds_cpu : alarm.arn],
    [for alarm in aws_cloudwatch_metric_alarm.rds_free_storage : alarm.arn],
    [for alarm in aws_cloudwatch_metric_alarm.rds_connections : alarm.arn]
  )
}

output "cloudwatch_alarm_names" {
  description = "Flat list of names for all CloudWatch alarms created by this stack."
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.security_metrics : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.s3_bucket_size : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.rds_cpu : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.rds_free_storage : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.rds_connections : alarm.alarm_name]
  )
}

output "cloudwatch_alarms_by_type" {
  description = "Map of alarm type to alarm ARN (or instance/bucket/db maps for resource-scoped alarms)."
  value = {
    security_metrics = { for k, alarm in aws_cloudwatch_metric_alarm.security_metrics : k => alarm.arn }
    ec2_cpu          = { for k, alarm in aws_cloudwatch_metric_alarm.ec2_cpu : k => alarm.arn }
    s3_bucket_size   = { for k, alarm in aws_cloudwatch_metric_alarm.s3_bucket_size : k => alarm.arn }
    rds_cpu          = { for k, alarm in aws_cloudwatch_metric_alarm.rds_cpu : k => alarm.arn }
    rds_free_storage = { for k, alarm in aws_cloudwatch_metric_alarm.rds_free_storage : k => alarm.arn }
    rds_connections  = { for k, alarm in aws_cloudwatch_metric_alarm.rds_connections : k => alarm.arn }
  }
}

output "config_rule_arns" {
  description = "Map of Config rule key to rule ARN."
  value       = { for k, rule in aws_config_config_rule.managed : k => rule.arn }
}

output "config_rule_names" {
  description = "Map of Config rule key to rule name."
  value       = { for k, rule in aws_config_config_rule.managed : k => rule.name }
}

output "resources_by_category" {
  description = "Summary of created resources grouped by monitoring category."
  value = {
    console_security = [
      for k in keys(local.console_security_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    iam_changes = [
      for k in keys(local.iam_change_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    cloudtrail_changes = [
      for k in keys(local.cloudtrail_change_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    critical_services = [
      for k in keys(local.critical_service_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    network_changes = [
      for k in keys(local.network_change_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    s3_policy_changes = [
      for k in keys(local.s3_policy_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    cloudwatch_log_deletion = [
      for k in keys(local.cloudwatch_log_deletion_rules) : aws_cloudwatch_event_rule.security[k].arn
    ]
    config_compliance = concat(
      [for k in keys(local.config_compliance_rules) : aws_cloudwatch_event_rule.security[k].arn],
      [for rule in aws_config_config_rule.managed : rule.arn]
    )
    metric_alarms = [for alarm in aws_cloudwatch_metric_alarm.security_metrics : alarm.arn]
    ec2_alarms    = [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu : alarm.arn]
    s3_alarms     = [for alarm in aws_cloudwatch_metric_alarm.s3_bucket_size : alarm.arn]
    rds_alarms = concat(
      [for alarm in aws_cloudwatch_metric_alarm.rds_cpu : alarm.arn],
      [for alarm in aws_cloudwatch_metric_alarm.rds_free_storage : alarm.arn],
      [for alarm in aws_cloudwatch_metric_alarm.rds_connections : alarm.arn]
    )
  }
}
