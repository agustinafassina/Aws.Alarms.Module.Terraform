resource "aws_config_config_rule" "managed" {
  for_each = local.config_rule_definitions

  name        = each.value.name
  description = each.value.description

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  input_parameters = each.value.input_parameters

  tags = merge(local.common_tags, {
    AlarmType = each.key
    Severity  = "high"
  })

  lifecycle {
    precondition {
      condition     = length(var.config_role_arn) > 0
      error_message = "config_role_arn must be set to an existing AWS Config service role ARN when enable_config_compliance is true."
    }
  }
}
