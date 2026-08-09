resource "aws_cloudwatch_log_metric_filter" "security" {
  for_each = local.metric_filter_definitions

  name           = each.value.name
  log_group_name = var.cloudtrail_log_group_name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.value.metric_name
    namespace     = var.metric_namespace
    value         = each.value.metric_value
    default_value = "0"
  }
}
