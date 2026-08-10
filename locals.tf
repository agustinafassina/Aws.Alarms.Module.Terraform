locals {
  name_prefix = "tf-account-${var.account_alias}"

  common_tags = merge(
    var.tags,
    {
      Name      = local.name_prefix
      ManagedBy = "terraform"
      Module    = "account-alarms"
    },
    { Environment = var.environment }
  )

  create_sns_topic = var.create_sns_topic
  sns_topic_name   = "${local.name_prefix}-alerts"

  created_sns_topic_arn = one(aws_sns_topic.alerts[*].arn)

  effective_alarm_actions = distinct(compact(concat(
    local.create_sns_topic ? [local.created_sns_topic_arn] : [],
    var.alarm_actions
  )))

  effective_ok_actions = distinct(compact(concat(
    local.create_sns_topic && var.sns_notify_on_ok ? [local.created_sns_topic_arn] : [],
    var.ok_actions
  )))

  effective_insufficient_data_actions = distinct(compact(concat(
    local.create_sns_topic && var.sns_notify_on_insufficient_data ? [local.created_sns_topic_arn] : [],
    var.insufficient_data_actions
  )))

  sns_target_arns = toset(local.effective_alarm_actions)

  eventbridge_rule_names = {
    unauthorized_console_login = "${local.name_prefix}-unauthorized-console-login"
    console_login_without_mfa  = "${local.name_prefix}-console-login-without-mfa"
    root_account_activity      = "${local.name_prefix}-root-account-activity"
    iam_changes                = "${local.name_prefix}-iam-changes"
    cloudtrail_changes         = "${local.name_prefix}-cloudtrail-changes"
    critical_service_changes   = "${local.name_prefix}-critical-service-changes"
    config_non_compliant       = "${local.name_prefix}-config-non-compliant"
    network_acl_sg_changes     = "${local.name_prefix}-network-acl-sg-changes"
    s3_policy_changes          = "${local.name_prefix}-s3-policy-changes"
    cloudwatch_log_deletion    = "${local.name_prefix}-cloudwatch-log-deletion"
  }

  eventbridge_event_patterns = {
    unauthorized_console_login = jsonencode({
      source      = ["aws.signin"]
      detail-type = ["AWS Console Sign In via CloudTrail"]
      detail = {
        eventName = ["ConsoleLogin"]
        errorCode = [{ exists = true }]
      }
    })

    console_login_without_mfa = jsonencode({
      source      = ["aws.signin"]
      detail-type = ["AWS Console Sign In via CloudTrail"]
      detail = {
        eventName = ["ConsoleLogin"]
        additionalEventData = {
          MFAUsed = ["No"]
        }
      }
    })

    root_account_activity = jsonencode({
      detail-type = ["AWS API Call via CloudTrail", "AWS Console Sign In via CloudTrail"]
      detail = {
        userIdentity = {
          type = ["Root"]
        }
      }
    })

    iam_changes = jsonencode({
      source      = ["aws.iam"]
      detail-type = ["AWS API Call via CloudTrail"]
      detail = {
        eventSource = ["iam.amazonaws.com"]
        eventName = [
          "CreatePolicy",
          "DeletePolicy",
          "CreatePolicyVersion",
          "DeletePolicyVersion",
          "PutUserPolicy",
          "PutGroupPolicy",
          "PutRolePolicy",
          "DeleteUserPolicy",
          "DeleteGroupPolicy",
          "DeleteRolePolicy",
          "CreateRole",
          "DeleteRole",
          "UpdateAssumeRolePolicy",
          "AttachRolePolicy",
          "DetachRolePolicy",
          "AttachUserPolicy",
          "DetachUserPolicy",
          "AttachGroupPolicy",
          "DetachGroupPolicy"
        ]
      }
    })

    cloudtrail_changes = jsonencode({
      source      = ["aws.cloudtrail"]
      detail-type = ["AWS API Call via CloudTrail"]
      detail = {
        eventSource = ["cloudtrail.amazonaws.com"]
        eventName = [
          "StopLogging",
          "DeleteTrail",
          "UpdateTrail"
        ]
      }
    })

    critical_service_changes = jsonencode({
      detail-type = ["AWS API Call via CloudTrail"]
      detail = {
        eventName = [
          "ScheduleKeyDeletion",
          "DisableKey",
          "DisableSecurityHub",
          "BatchDisableStandards",
          "DeleteMembers",
          "DisassociateFromAdministratorAccount",
          "DisableImportFindingsForProduct",
          "DeleteDetector",
          "UpdateDetector",
          "StopMonitoringMembers",
          "DisassociateFromMasterAccount",
          "DisableOrganizationAdminAccount",
          "CreateUser",
          "CreateAccessKey"
        ]
      }
    })

    config_non_compliant = jsonencode({
      source      = ["aws.config"]
      detail-type = ["Config Rules Compliance Change"]
      detail = {
        newEvaluationResult = {
          complianceType = ["NON_COMPLIANT"]
        }
      }
    })

    network_acl_sg_changes = jsonencode({
      source      = ["aws.ec2"]
      detail-type = ["AWS API Call via CloudTrail"]
      detail = {
        eventSource = ["ec2.amazonaws.com"]
        eventName = [
          "CreateSecurityGroup",
          "DeleteSecurityGroup",
          "AuthorizeSecurityGroupIngress",
          "AuthorizeSecurityGroupEgress",
          "RevokeSecurityGroupIngress",
          "RevokeSecurityGroupEgress",
          "ModifySecurityGroupRules",
          "CreateNetworkAcl",
          "DeleteNetworkAcl",
          "CreateNetworkAclEntry",
          "DeleteNetworkAclEntry",
          "ReplaceNetworkAclEntry",
          "ReplaceNetworkAclAssociation"
        ]
      }
    })

    s3_policy_changes = jsonencode({
      source      = ["aws.s3"]
      detail-type = ["AWS API Call via CloudTrail"]
      detail = {
        eventSource = ["s3.amazonaws.com"]
        eventName = [
          "PutBucketPolicy",
          "DeleteBucketPolicy",
          "PutBucketPublicAccessBlock",
          "DeleteBucketPublicAccessBlock",
          "PutAccountPublicAccessBlock",
          "DeleteAccountPublicAccessBlock"
        ]
      }
    })

    cloudwatch_log_deletion = jsonencode({
      source      = ["aws.logs"]
      detail-type = ["AWS API Call via CloudTrail"]
      detail = {
        eventSource = ["logs.amazonaws.com"]
        eventName = [
          "DeleteLogGroup",
          "DeleteLogStream"
        ]
      }
    })
  }

  console_security_rules = var.enable_console_security_monitoring ? {
    unauthorized_console_login = {
      name          = local.eventbridge_rule_names.unauthorized_console_login
      description   = "Notify on failed AWS console sign-in attempts."
      event_pattern = local.eventbridge_event_patterns.unauthorized_console_login
      severity      = "critical"
    }
    console_login_without_mfa = {
      name          = local.eventbridge_rule_names.console_login_without_mfa
      description   = "Notify on successful console sign-in without MFA."
      event_pattern = local.eventbridge_event_patterns.console_login_without_mfa
      severity      = "high"
    }
    root_account_activity = {
      name          = local.eventbridge_rule_names.root_account_activity
      description   = "Notify on AWS root account activity."
      event_pattern = local.eventbridge_event_patterns.root_account_activity
      severity      = "critical"
    }
  } : {}

  iam_change_rules = var.enable_iam_change_monitoring ? {
    iam_changes = {
      name          = local.eventbridge_rule_names.iam_changes
      description   = "Notify on IAM policy and role create, update, or delete events."
      event_pattern = local.eventbridge_event_patterns.iam_changes
      severity      = "high"
    }
  } : {}

  cloudtrail_change_rules = var.enable_cloudtrail_monitoring ? {
    cloudtrail_changes = {
      name          = local.eventbridge_rule_names.cloudtrail_changes
      description   = "Notify on CloudTrail logging disable, delete, or update events."
      event_pattern = local.eventbridge_event_patterns.cloudtrail_changes
      severity      = "critical"
    }
  } : {}

  critical_service_rules = var.enable_critical_service_monitoring ? {
    critical_service_changes = {
      name          = local.eventbridge_rule_names.critical_service_changes
      description   = "Notify on sensitive KMS, Security Hub/GuardDuty disable or disassociate, and IAM identity events."
      event_pattern = local.eventbridge_event_patterns.critical_service_changes
      severity      = "critical"
    }
  } : {}

  config_compliance_rules = var.enable_config_compliance ? {
    config_non_compliant = {
      name          = local.eventbridge_rule_names.config_non_compliant
      description   = "Notify when an AWS Config rule transitions to NON_COMPLIANT."
      event_pattern = local.eventbridge_event_patterns.config_non_compliant
      severity      = "high"
    }
  } : {}

  network_change_rules = var.enable_network_change_monitoring ? {
    network_acl_sg_changes = {
      name          = local.eventbridge_rule_names.network_acl_sg_changes
      description   = "Notify on Security Group and Network ACL create, modify, or delete events."
      event_pattern = local.eventbridge_event_patterns.network_acl_sg_changes
      severity      = "high"
    }
  } : {}

  s3_policy_rules = var.enable_s3_policy_monitoring ? {
    s3_policy_changes = {
      name          = local.eventbridge_rule_names.s3_policy_changes
      description   = "Notify on S3 bucket policy and Block Public Access changes."
      event_pattern = local.eventbridge_event_patterns.s3_policy_changes
      severity      = "critical"
    }
  } : {}

  cloudwatch_log_deletion_rules = var.enable_cloudwatch_log_deletion_monitoring ? {
    cloudwatch_log_deletion = {
      name          = local.eventbridge_rule_names.cloudwatch_log_deletion
      description   = "Notify on CloudWatch Logs DeleteLogGroup or DeleteLogStream events."
      event_pattern = local.eventbridge_event_patterns.cloudwatch_log_deletion
      severity      = "high"
    }
  } : {}

  eventbridge_rules = merge(
    local.console_security_rules,
    local.iam_change_rules,
    local.cloudtrail_change_rules,
    local.critical_service_rules,
    local.config_compliance_rules,
    local.network_change_rules,
    local.s3_policy_rules,
    local.cloudwatch_log_deletion_rules
  )

  eventbridge_targets = {
    for pair in setproduct(keys(local.eventbridge_rules), local.sns_target_arns) :
    "${pair[0]}|${pair[1]}" => {
      rule_key = pair[0]
      arn      = pair[1]
    }
  }

  metric_filter_definitions = merge(
    var.enable_access_key_monitoring ? {
      access_key_api_burst = {
        name               = "${local.name_prefix}-access-key-api-burst"
        pattern            = "{ $.userIdentity.accessKeyId = \"*\" }"
        metric_name        = "AccessKeyApiBurst"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-access-key-api-burst"
        alarm_description  = "Elevated CloudTrail activity using IAM access keys."
        threshold          = var.access_key_api_burst_threshold
        period             = var.access_key_api_burst_period
        evaluation_periods = var.access_key_api_burst_evaluation_periods
        severity           = "warning"
      }
      access_key_management = {
        name               = "${local.name_prefix}-access-key-management"
        pattern            = "{ ($.eventName = CreateAccessKey) || ($.eventName = UpdateAccessKey) }"
        metric_name        = "AccessKeyManagement"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-access-key-management"
        alarm_description  = "IAM access key create or update detected."
        threshold          = var.access_key_management_threshold
        period             = var.access_key_management_period
        evaluation_periods = var.access_key_management_evaluation_periods
        severity           = "high"
      }
    } : {},
    var.enable_ec2_usage_alarms ? {
      ec2_run_instances_spike = {
        name               = "${local.name_prefix}-ec2-run-instances-spike"
        pattern            = "{ ($.eventName = RunInstances) || ($.eventName = StartInstances) }"
        metric_name        = "Ec2RunInstancesSpike"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-ec2-run-instances-spike"
        alarm_description  = "Unusual EC2 RunInstances or StartInstances activity."
        threshold          = var.ec2_run_instances_threshold
        period             = var.ec2_run_instances_period
        evaluation_periods = var.ec2_run_instances_evaluation_periods
        severity           = "warning"
      }
    } : {},
    var.enable_s3_usage_alarms ? {
      s3_api_burst = {
        name               = "${local.name_prefix}-s3-api-burst"
        pattern            = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = GetObject) || ($.eventName = PutObject) || ($.eventName = DeleteObject)) }"
        metric_name        = "S3ApiBurst"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-s3-api-burst"
        alarm_description  = "Unusual S3 object API activity volume."
        threshold          = var.s3_api_burst_threshold
        period             = var.s3_api_burst_period
        evaluation_periods = var.s3_api_burst_evaluation_periods
        severity           = "warning"
      }
    } : {},
    var.enable_rds_usage_alarms ? {
      rds_change_spike = {
        name               = "${local.name_prefix}-rds-change-spike"
        pattern            = "{ ($.eventSource = rds.amazonaws.com) && (($.eventName = CreateDBInstance) || ($.eventName = ModifyDBInstance)) }"
        metric_name        = "RdsChangeSpike"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-rds-change-spike"
        alarm_description  = "RDS CreateDBInstance or ModifyDBInstance activity detected."
        threshold          = var.rds_change_threshold
        period             = var.rds_change_period
        evaluation_periods = var.rds_change_evaluation_periods
        severity           = "high"
      }
    } : {},
    var.enable_access_denied_alarm ? {
      access_denied = {
        name               = "${local.name_prefix}-access-denied"
        pattern            = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
        metric_name        = "AccessDenied"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-access-denied"
        alarm_description  = "Elevated AccessDenied or UnauthorizedOperation CloudTrail events."
        threshold          = var.access_denied_threshold
        period             = var.access_denied_period
        evaluation_periods = var.access_denied_evaluation_periods
        severity           = "warning"
      }
    } : {},
    var.enable_open_security_group_monitoring ? {
      open_security_group = {
        name               = "${local.name_prefix}-open-security-group"
        pattern            = "{ (($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress)) && ($.requestParameters.cidrIp = \"0.0.0.0/0\" || $.requestParameters.cidrIpv6 = \"::/0\" || $.requestParameters.ipPermissions.items.*.ipRanges.items.*.cidrIp = \"0.0.0.0/0\" || $.requestParameters.ipPermissions.items.*.ipv6Ranges.items.*.cidrIpv6 = \"::/0\") }"
        metric_name        = "OpenSecurityGroup"
        metric_value       = "1"
        alarm_name         = "${local.name_prefix}-open-security-group"
        alarm_description  = "Security Group ingress or egress opened to 0.0.0.0/0 or ::/0."
        threshold          = var.open_security_group_threshold
        period             = var.open_security_group_period
        evaluation_periods = var.open_security_group_evaluation_periods
        severity           = "critical"
      }
    } : {}
  )

  config_rule_definitions = var.enable_config_compliance ? merge(
    {
      root_account_mfa_enabled = {
        name              = "${local.name_prefix}-root-account-mfa-enabled"
        source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
        description       = "Checks whether MFA is enabled for the root account."
        input_parameters  = null
      }
      s3_bucket_public_read_prohibited = {
        name              = "${local.name_prefix}-s3-bucket-public-read-prohibited"
        source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
        description       = "Checks that S3 buckets do not allow public read access."
        input_parameters  = null
      }
      s3_bucket_public_write_prohibited = {
        name              = "${local.name_prefix}-s3-bucket-public-write-prohibited"
        source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
        description       = "Checks that S3 buckets do not allow public write access."
        input_parameters  = null
      }
      encrypted_volumes = {
        name              = "${local.name_prefix}-encrypted-volumes"
        source_identifier = "ENCRYPTED_VOLUMES"
        description       = "Checks whether EBS volumes are encrypted."
        input_parameters  = null
      }
      rds_storage_encrypted = {
        name              = "${local.name_prefix}-rds-storage-encrypted"
        source_identifier = "RDS_STORAGE_ENCRYPTED"
        description       = "Checks whether RDS storage encryption is enabled."
        input_parameters  = null
      }
      cloudtrail_enabled = {
        name              = "${local.name_prefix}-cloudtrail-enabled"
        source_identifier = "CLOUD_TRAIL_ENABLED"
        description       = "Checks whether AWS CloudTrail is enabled."
        input_parameters  = null
      }
      iam_password_policy = {
        name              = "${local.name_prefix}-iam-password-policy"
        source_identifier = "IAM_PASSWORD_POLICY"
        description       = "Checks that the account password policy meets strength requirements."
        input_parameters = jsonencode({
          RequireUppercaseCharacters = "true"
          RequireLowercaseCharacters = "true"
          RequireSymbols             = "true"
          RequireNumbers             = "true"
          MinimumPasswordLength      = "14"
          PasswordReusePrevention    = "24"
          MaxPasswordAge             = "90"
        })
      }
    },
    var.enable_access_key_monitoring ? {
      access_keys_rotated = {
        name              = "${local.name_prefix}-access-keys-rotated"
        source_identifier = "ACCESS_KEYS_ROTATED"
        description       = "Checks whether IAM access keys are rotated within the configured maximum age."
        input_parameters = jsonencode({
          maxAccessKeyAge = tostring(var.access_key_max_age_days)
        })
      }
      iam_user_unused_credentials = {
        name              = "${local.name_prefix}-iam-user-unused-credentials"
        source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
        description       = "Checks whether IAM users have unused credentials older than the configured age."
        input_parameters = jsonencode({
          maxCredentialUsageAge = tostring(var.unused_credentials_max_age_days)
        })
      }
    } : {}
  ) : {}

  ec2_instance_ids = toset(var.ec2_instance_ids)
  s3_bucket_names  = toset(var.s3_bucket_names)
  rds_db_ids       = toset(var.rds_db_instance_identifiers)

  ec2_cpu_alarm_names = {
    for instance_id in local.ec2_instance_ids :
    instance_id => "${local.name_prefix}-ec2-cpu-${instance_id}"
  }

  s3_size_alarm_names = {
    for bucket in local.s3_bucket_names :
    bucket => "${local.name_prefix}-s3-size-${bucket}"
  }

  rds_cpu_alarm_names = {
    for db_id in local.rds_db_ids :
    db_id => "${local.name_prefix}-rds-cpu-${db_id}"
  }

  rds_free_storage_alarm_names = {
    for db_id in local.rds_db_ids :
    db_id => "${local.name_prefix}-rds-free-storage-${db_id}"
  }

  rds_connections_alarm_names = {
    for db_id in local.rds_db_ids :
    db_id => "${local.name_prefix}-rds-connections-${db_id}"
  }
}
