resource "aws_cloudwatch_event_rule" "security" {
  for_each = local.eventbridge_rules

  name          = each.value.name
  description   = each.value.description
  event_pattern = each.value.event_pattern
  state         = "ENABLED"
  tags = merge(local.common_tags, {
    AlarmType = each.key
    Severity  = each.value.severity
  })
}

resource "aws_cloudwatch_event_target" "security_sns" {
  for_each = local.eventbridge_targets

  rule      = aws_cloudwatch_event_rule.security[each.value.rule_key].name
  target_id = substr(md5(each.key), 0, 32)
  arn       = each.value.arn
}
