account_alias = "prod"
environment   = "prod"
aws_region    = "eu-west-1"

create_sns_topic = true
notification_emails = [
  "platform-alerts-prod@example.com",
  "oncall-prod@example.com",
]
sns_notify_on_ok                = true
sns_notify_on_insufficient_data = true

alarm_actions             = []
ok_actions                = []
insufficient_data_actions = []

cloudtrail_log_group_name = "/aws/cloudtrail/prod"
config_role_arn           = "arn:aws:iam::123456789012:role/aws-config-role-prod"

enable_access_key_monitoring              = true
enable_console_security_monitoring        = true
enable_iam_change_monitoring              = true
enable_cloudtrail_monitoring              = true
enable_critical_service_monitoring        = true
enable_network_change_monitoring          = true
enable_s3_policy_monitoring               = true
enable_open_security_group_monitoring     = true
enable_cloudwatch_log_deletion_monitoring = true
enable_ec2_usage_alarms                   = true
enable_s3_usage_alarms                    = true
enable_rds_usage_alarms                   = true
enable_config_compliance                  = true
enable_access_denied_alarm                = true

access_key_api_burst_threshold  = 100
access_key_management_threshold = 0
access_key_max_age_days         = 90
unused_credentials_max_age_days = 90
ec2_run_instances_threshold     = 3
s3_api_burst_threshold          = 300
rds_change_threshold            = 0
access_denied_threshold         = 20

ec2_cpu_threshold                  = 80
s3_bucket_size_threshold_bytes     = 1099511627776
rds_cpu_threshold                  = 80
rds_free_storage_threshold_bytes   = 2147483648
rds_database_connections_threshold = 100

ec2_instance_ids            = []
s3_bucket_names             = []
rds_db_instance_identifiers = []

tags = {
  Project = "account-alarms"
  Owner   = "platform"
}
