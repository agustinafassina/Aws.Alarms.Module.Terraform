account_alias = "dev"
environment   = "dev"
aws_region    = "eu-west-1"

alarm_actions = [
  "arn:aws:sns:eu-west-1:123456789012:account-alerts-dev",
]

ok_actions                = []
insufficient_data_actions = []

cloudtrail_log_group_name = "/aws/cloudtrail/dev"
config_role_arn           = "arn:aws:iam::123456789012:role/aws-config-role-dev"

enable_access_key_monitoring              = true
enable_console_security_monitoring        = true
enable_iam_change_monitoring              = true
enable_cloudtrail_monitoring              = true
enable_critical_service_monitoring        = true
enable_network_change_monitoring          = true
enable_s3_policy_monitoring               = true
enable_open_security_group_monitoring     = true
enable_cloudwatch_log_deletion_monitoring = false
enable_ec2_usage_alarms                   = true
enable_s3_usage_alarms                    = false
enable_rds_usage_alarms                   = false
enable_config_compliance                  = true
enable_access_denied_alarm                = true

access_key_api_burst_threshold  = 200
access_key_management_threshold = 0
access_key_max_age_days         = 90
unused_credentials_max_age_days = 90
ec2_run_instances_threshold     = 10
s3_api_burst_threshold          = 1000
rds_change_threshold            = 0
access_denied_threshold         = 50

ec2_instance_ids            = []
s3_bucket_names             = []
rds_db_instance_identifiers = []

tags = {
  Project = "account-alarms"
  Owner   = "platform"
}
