variable "account_alias" {
  description = "Logical account alias used to build resource names (tf-account-<account_alias>-...)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$", var.account_alias))
    error_message = "account_alias must be 1-63 characters, alphanumeric and hyphens, and must start/end with alphanumeric."
  }
}

variable "environment" {
  description = "Environment identifier applied as a tag on created resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the provider and region-scoped resources."
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Common tags applied to all resources created by this stack."
  type        = map(string)
  default     = {}
}

variable "alarm_actions" {
  description = "ARNs to notify when an alarm transitions to ALARM or when an EventBridge rule matches."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "ARNs to notify when an alarm transitions to OK."
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "ARNs to notify when an alarm transitions to INSUFFICIENT_DATA."
  type        = list(string)
  default     = []
}

variable "cloudtrail_log_group_name" {
  description = "Existing CloudWatch Logs group name where CloudTrail delivers management events."
  type        = string

  validation {
    condition     = can(regex("^/", var.cloudtrail_log_group_name))
    error_message = "cloudtrail_log_group_name must start with '/'."
  }
}

variable "config_role_arn" {
  description = "Existing IAM role ARN used by AWS Config managed rules (recorder must already be active)."
  type        = string
  default     = ""
}

variable "enable_access_key_monitoring" {
  description = "Create metric filters, alarms, and Config rules related to IAM access keys."
  type        = bool
  default     = true
}

variable "enable_console_security_monitoring" {
  description = "Create EventBridge rules for failed console login, console login without MFA, and root activity."
  type        = bool
  default     = true
}

variable "enable_iam_change_monitoring" {
  description = "Create EventBridge rules for IAM policy and role changes."
  type        = bool
  default     = true
}

variable "enable_cloudtrail_monitoring" {
  description = "Create EventBridge rules for CloudTrail StopLogging, DeleteTrail, and UpdateTrail."
  type        = bool
  default     = true
}

variable "enable_critical_service_monitoring" {
  description = "Create EventBridge rules for sensitive KMS, Security Hub, GuardDuty disable/disassociate, and IAM user creation events."
  type        = bool
  default     = true
}

variable "enable_network_change_monitoring" {
  description = "Create EventBridge rules for Security Group and Network ACL create, modify, and delete events."
  type        = bool
  default     = true
}

variable "enable_s3_policy_monitoring" {
  description = "Create EventBridge rules for S3 bucket policy and Block Public Access changes."
  type        = bool
  default     = true
}

variable "enable_open_security_group_monitoring" {
  description = "Create a metric filter and alarm for AuthorizeSecurityGroupIngress/Egress open to 0.0.0.0/0 (or ::/0)."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_log_deletion_monitoring" {
  description = "Create EventBridge rules for CloudWatch Logs DeleteLogGroup and DeleteLogStream events."
  type        = bool
  default     = true
}

variable "enable_ec2_usage_alarms" {
  description = "Create CloudTrail-based EC2 usage spike alarms and optional per-instance metric alarms."
  type        = bool
  default     = true
}

variable "enable_s3_usage_alarms" {
  description = "Create CloudTrail-based S3 API burst alarms and optional per-bucket metric alarms."
  type        = bool
  default     = true
}

variable "enable_rds_usage_alarms" {
  description = "Create CloudTrail-based RDS change alarms and optional per-instance metric alarms."
  type        = bool
  default     = true
}

variable "enable_config_compliance" {
  description = "Create AWS Config managed rules and EventBridge notifications for NON_COMPLIANT changes."
  type        = bool
  default     = true
}

variable "enable_access_denied_alarm" {
  description = "Create a metric filter and alarm for elevated AccessDenied CloudTrail events."
  type        = bool
  default     = true
}

variable "metric_namespace" {
  description = "Custom CloudWatch metric namespace for CloudTrail metric filters."
  type        = string
  default     = "AccountSecurity"
}

variable "access_key_api_burst_threshold" {
  description = "Threshold for CloudTrail events that include an accessKeyId within the evaluation window."
  type        = number
  default     = 100
}

variable "access_key_api_burst_period" {
  description = "Period in seconds for the access key API burst alarm."
  type        = number
  default     = 300
}

variable "access_key_api_burst_evaluation_periods" {
  description = "Evaluation periods for the access key API burst alarm."
  type        = number
  default     = 1
}

variable "access_key_management_threshold" {
  description = "Threshold for CreateAccessKey/UpdateAccessKey events within the evaluation window."
  type        = number
  default     = 0
}

variable "access_key_management_period" {
  description = "Period in seconds for the access key management alarm."
  type        = number
  default     = 300
}

variable "access_key_management_evaluation_periods" {
  description = "Evaluation periods for the access key management alarm."
  type        = number
  default     = 1
}

variable "access_key_max_age_days" {
  description = "Maximum access key age in days for the access-keys-rotated Config rule."
  type        = number
  default     = 90
}

variable "unused_credentials_max_age_days" {
  description = "Maximum unused credential age in days for iam-user-unused-credentials-check."
  type        = number
  default     = 90
}

variable "ec2_run_instances_threshold" {
  description = "Threshold for RunInstances/StartInstances CloudTrail events within the evaluation window."
  type        = number
  default     = 5
}

variable "ec2_run_instances_period" {
  description = "Period in seconds for the EC2 instance launch spike alarm."
  type        = number
  default     = 300
}

variable "ec2_run_instances_evaluation_periods" {
  description = "Evaluation periods for the EC2 instance launch spike alarm."
  type        = number
  default     = 1
}

variable "s3_api_burst_threshold" {
  description = "Threshold for GetObject/PutObject/DeleteObject CloudTrail events within the evaluation window."
  type        = number
  default     = 500
}

variable "s3_api_burst_period" {
  description = "Period in seconds for the S3 API burst alarm."
  type        = number
  default     = 300
}

variable "s3_api_burst_evaluation_periods" {
  description = "Evaluation periods for the S3 API burst alarm."
  type        = number
  default     = 1
}

variable "rds_change_threshold" {
  description = "Threshold for CreateDBInstance/ModifyDBInstance CloudTrail events within the evaluation window."
  type        = number
  default     = 0
}

variable "rds_change_period" {
  description = "Period in seconds for the RDS change alarm."
  type        = number
  default     = 300
}

variable "rds_change_evaluation_periods" {
  description = "Evaluation periods for the RDS change alarm."
  type        = number
  default     = 1
}

variable "access_denied_threshold" {
  description = "Threshold for AccessDenied CloudTrail events within the evaluation window."
  type        = number
  default     = 20
}

variable "access_denied_period" {
  description = "Period in seconds for the AccessDenied alarm."
  type        = number
  default     = 300
}

variable "access_denied_evaluation_periods" {
  description = "Evaluation periods for the AccessDenied alarm."
  type        = number
  default     = 1
}

variable "open_security_group_threshold" {
  description = "Threshold for Security Group rules opened to 0.0.0.0/0 or ::/0 within the evaluation window."
  type        = number
  default     = 0
}

variable "open_security_group_period" {
  description = "Period in seconds for the open Security Group alarm."
  type        = number
  default     = 300
}

variable "open_security_group_evaluation_periods" {
  description = "Evaluation periods for the open Security Group alarm."
  type        = number
  default     = 1
}

variable "ec2_instance_ids" {
  description = "Optional EC2 instance IDs for native CloudWatch CPU alarms."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.ec2_instance_ids : can(regex("^i-[a-f0-9]{8,17}$", id))
    ])
    error_message = "Each ec2_instance_ids value must be a valid EC2 instance ID (i-xxxxxxxx)."
  }
}

variable "ec2_cpu_threshold" {
  description = "CPUUtilization threshold percentage for optional per-instance EC2 alarms."
  type        = number
  default     = 80

  validation {
    condition     = var.ec2_cpu_threshold >= 0 && var.ec2_cpu_threshold <= 100
    error_message = "ec2_cpu_threshold must be between 0 and 100."
  }
}

variable "ec2_cpu_period" {
  description = "Period in seconds for optional per-instance EC2 CPU alarms."
  type        = number
  default     = 300
}

variable "ec2_cpu_evaluation_periods" {
  description = "Evaluation periods for optional per-instance EC2 CPU alarms."
  type        = number
  default     = 2
}

variable "s3_bucket_names" {
  description = "Optional S3 bucket names for native CloudWatch bucket-size alarms."
  type        = list(string)
  default     = []
}

variable "s3_bucket_size_threshold_bytes" {
  description = "BucketSizeBytes threshold for optional per-bucket S3 alarms."
  type        = number
  default     = 1099511627776
}

variable "s3_bucket_size_period" {
  description = "Period in seconds for optional per-bucket S3 size alarms."
  type        = number
  default     = 86400
}

variable "s3_bucket_size_evaluation_periods" {
  description = "Evaluation periods for optional per-bucket S3 size alarms."
  type        = number
  default     = 1
}

variable "rds_db_instance_identifiers" {
  description = "Optional RDS DB instance identifiers for native CloudWatch alarms."
  type        = list(string)
  default     = []
}

variable "rds_cpu_threshold" {
  description = "CPUUtilization threshold percentage for optional per-instance RDS alarms."
  type        = number
  default     = 80

  validation {
    condition     = var.rds_cpu_threshold >= 0 && var.rds_cpu_threshold <= 100
    error_message = "rds_cpu_threshold must be between 0 and 100."
  }
}

variable "rds_cpu_period" {
  description = "Period in seconds for optional per-instance RDS CPU alarms."
  type        = number
  default     = 300
}

variable "rds_cpu_evaluation_periods" {
  description = "Evaluation periods for optional per-instance RDS CPU alarms."
  type        = number
  default     = 2
}

variable "rds_free_storage_threshold_bytes" {
  description = "FreeStorageSpace threshold in bytes for optional per-instance RDS alarms."
  type        = number
  default     = 2147483648
}

variable "rds_free_storage_period" {
  description = "Period in seconds for optional per-instance RDS free storage alarms."
  type        = number
  default     = 300
}

variable "rds_free_storage_evaluation_periods" {
  description = "Evaluation periods for optional per-instance RDS free storage alarms."
  type        = number
  default     = 2
}

variable "rds_database_connections_threshold" {
  description = "DatabaseConnections threshold for optional per-instance RDS alarms."
  type        = number
  default     = 100
}

variable "rds_database_connections_period" {
  description = "Period in seconds for optional per-instance RDS connection alarms."
  type        = number
  default     = 300
}

variable "rds_database_connections_evaluation_periods" {
  description = "Evaluation periods for optional per-instance RDS connection alarms."
  type        = number
  default     = 2
}
