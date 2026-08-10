# AWS Account-Level Alarms

English | [Español](README.es.md)

Root Terraform stack that deploys account-level security and usage monitoring for AWS. It creates an SNS alerts topic with email subscriptions, EventBridge rules, CloudWatch Logs metric filters, CloudWatch metric alarms, and AWS Config managed rules. CloudTrail log delivery and the Config recorder are **not** created here; they must already exist and are passed in as variables.

![Architecture](./docs/architecture.png)

## Features

- Managed SNS topic with email subscriptions and publish policy for EventBridge / CloudWatch
- Access key inactivity / rotation compliance and burst usage alarms
- Unauthorized and suspicious console sign-in notifications
- IAM policy and role change monitoring
- Security Group / Network ACL change monitoring
- S3 bucket policy and Block Public Access change monitoring
- Open Security Group rules to `0.0.0.0/0` or `::/0`
- CloudWatch Logs deletion monitoring
- Unusual EC2, S3, and RDS usage signals (CloudTrail-based and optional per-resource alarms)
- CloudTrail and critical-service change monitoring (expanded GuardDuty / Security Hub disable coverage)
- AWS Config managed compliance rules with NON_COMPLIANT notifications

## Prerequisites

Before applying this stack, ensure the target account already has:

1. **CloudTrail** delivering management events to a CloudWatch Logs group (the name you pass as `cloudtrail_log_group_name`).
2. **AWS Config** with an active configuration recorder and delivery channel when `enable_config_compliance = true`.
3. The Config service role ARN in `config_role_arn` (used as a deployment precondition; the recorder must already use a suitable role).

Optional: set `create_sns_topic = false` and pass existing topic ARNs in `alarm_actions` / `ok_actions` / `insufficient_data_actions` if you already manage SNS elsewhere.

This stack does **not** create CloudTrail trails, Config recorders, or KMS keys.

## Notifications (SNS + email)

When `create_sns_topic = true` (default), the stack creates:

- SNS topic named `tf-account-<alias>-alerts`
- Email subscriptions for each address in `notification_emails`
- Topic policy allowing `sns:Publish` from `cloudwatch.amazonaws.com` and `events.amazonaws.com` (scoped to the account)

After apply, **confirm each email subscription** from the inbox confirmation message. Until confirmed, emails will not be delivered.

You can still append extra ARNs with `alarm_actions`. Use `sns_notify_on_ok` / `sns_notify_on_insufficient_data` to also wire the managed topic to OK / INSUFFICIENT_DATA alarm transitions.

## Architecture

| Mechanism | Use cases |
|---|---|
| EventBridge rules | Failed console login, login without MFA, root activity, IAM changes, CloudTrail tampering, critical service changes, SG/NACL changes, S3 policy/BPA changes, CloudWatch log deletion, Config NON_COMPLIANT |
| Metric filters + CloudWatch alarms | Access key API burst, access key management, EC2 launch spikes, S3 API burst, RDS changes, AccessDenied volume, open SG to `0.0.0.0/0` |
| AWS Config managed rules | Access key rotation, unused credentials, root MFA, S3 public access, EBS/RDS encryption, CloudTrail enabled, password policy |

## Naming

All logical names are defined in `locals.tf` and follow:

```text
tf-account-<account_alias>-<resource-type>
```

Examples:

- `tf-account-prod-unauthorized-console-login`
- `tf-account-prod-access-key-api-burst`
- `tf-account-prod-access-keys-rotated`

## Repository layout

| File | Purpose |
|---|---|
| `versions.tf` | Terraform and provider version constraints |
| `providers.tf` | AWS provider region |
| `variables.tf` | Inputs, enable flags, thresholds |
| `locals.tf` | Naming maps, event patterns, filter definitions |
| `data.tf` | Caller identity and region |
| `sns.tf` | Managed SNS topic, email subscriptions, and topic policy |
| `eventbridge_security.tf` | EventBridge rules and SNS targets |
| `metric_filters.tf` | CloudWatch Logs metric filters on CloudTrail |
| `cloudwatch_alarms.tf` | Metric and optional per-resource alarms |
| `config_rules.tf` | AWS Config managed rules |
| `outputs.tf` | Resource ARNs and category summary |
| `dev.tfvars` / `stage.tfvars` / `prod.tfvars` | Environment-specific values |

## Monitoring catalog

### EventBridge rules

| Key | Severity | Trigger |
|---|---|---|
| `unauthorized_console_login` | critical | `ConsoleLogin` with `errorCode` present |
| `console_login_without_mfa` | high | `ConsoleLogin` with `MFAUsed = No` |
| `root_account_activity` | critical | CloudTrail / console events from `userIdentity.type = Root` |
| `iam_changes` | high | IAM policy and role create / update / delete APIs |
| `cloudtrail_changes` | critical | `StopLogging`, `DeleteTrail`, `UpdateTrail` |
| `critical_service_changes` | critical | KMS key disable/delete schedule; Security Hub disable / standards disable / disassociate; GuardDuty detector delete/update/stop monitoring/disassociate; IAM `CreateUser` / `CreateAccessKey` |
| `config_non_compliant` | high | Config rule evaluation result `NON_COMPLIANT` |
| `network_acl_sg_changes` | high | Security Group and Network ACL create / modify / delete APIs |
| `s3_policy_changes` | critical | `Put/DeleteBucketPolicy`, `Put/DeleteBucketPublicAccessBlock`, account-level BPA changes |
| `cloudwatch_log_deletion` | high | `DeleteLogGroup`, `DeleteLogStream` |

### CloudWatch metric filters and alarms

| Key | Metric | Default threshold idea |
|---|---|---|
| `access_key_api_burst` | Events with `userIdentity.accessKeyId` | Configurable burst count |
| `access_key_management` | `CreateAccessKey` / `UpdateAccessKey` | Alert on any event (`> 0`) |
| `ec2_run_instances_spike` | `RunInstances` / `StartInstances` | Configurable spike count |
| `s3_api_burst` | S3 `GetObject` / `PutObject` / `DeleteObject` | Configurable burst count |
| `rds_change_spike` | `CreateDBInstance` / `ModifyDBInstance` | Alert on any event (`> 0`) |
| `access_denied` | `AccessDenied*` / `*UnauthorizedOperation` | Configurable volume |
| `open_security_group` | `AuthorizeSecurityGroupIngress/Egress` to `0.0.0.0/0` or `::/0` | Alert on any event (`> 0`) |

Open Security Group detection uses a **metric filter** (not EventBridge) because nested CloudTrail `ipPermissions` CIDR matching is unreliable in EventBridge patterns. Broader SG/NACL API activity is still covered by the `network_acl_sg_changes` EventBridge rule.

Custom metrics are published under the namespace set by `metric_namespace` (default `AccountSecurity`).

### Optional per-resource alarms

When lists are provided and the matching `enable_*` flag is true:

| Variable | Alarm |
|---|---|
| `ec2_instance_ids` | `CPUUtilization` per instance |
| `s3_bucket_names` | `BucketSizeBytes` per bucket |
| `rds_db_instance_identifiers` | `CPUUtilization`, `FreeStorageSpace`, `DatabaseConnections` |

### AWS Config managed rules

| Key | Managed identifier | Purpose |
|---|---|---|
| `access_keys_rotated` | `ACCESS_KEYS_ROTATED` | Access key age / rotation |
| `iam_user_unused_credentials` | `IAM_USER_UNUSED_CREDENTIALS_CHECK` | Unused IAM credentials |
| `root_account_mfa_enabled` | `ROOT_ACCOUNT_MFA_ENABLED` | Root MFA |
| `s3_bucket_public_read_prohibited` | `S3_BUCKET_PUBLIC_READ_PROHIBITED` | No public S3 read |
| `s3_bucket_public_write_prohibited` | `S3_BUCKET_PUBLIC_WRITE_PROHIBITED` | No public S3 write |
| `encrypted_volumes` | `ENCRYPTED_VOLUMES` | Encrypted EBS volumes |
| `rds_storage_encrypted` | `RDS_STORAGE_ENCRYPTED` | Encrypted RDS storage |
| `cloudtrail_enabled` | `CLOUD_TRAIL_ENABLED` | CloudTrail enabled |
| `iam_password_policy` | `IAM_PASSWORD_POLICY` | Strong account password policy |

Access-key Config rules are created only when both `enable_config_compliance` and `enable_access_key_monitoring` are true.

## How to use

Replace placeholder emails, Config role ARNs, and CloudTrail log group names in the corresponding `.tfvars` file.

### Initialize

```bash
terraform init
```

### Plan / apply per environment

```bash
terraform plan  -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Confirm every SNS email subscription after the first apply.

### Example overrides

```hcl
create_sns_topic = true
notification_emails = [
  "ops@example.com",
  "security@example.com",
]

# Or reuse an existing topic instead:
# create_sns_topic = false
# alarm_actions    = ["arn:aws:sns:eu-west-1:123456789012:existing-alerts"]

enable_s3_usage_alarms = true
s3_bucket_names        = ["my-app-assets"]

enable_ec2_usage_alarms = true
ec2_instance_ids        = ["i-0123456789abcdef0"]

enable_rds_usage_alarms = true
rds_db_instance_identifiers = ["orders-db"]
```

## Environment profiles

| Setting | `dev.tfvars` | `stage.tfvars` | `prod.tfvars` |
|---|---|---|---|
| SNS emails | One placeholder | One placeholder | Two placeholders |
| `sns_notify_on_ok` | false | true | true |
| `sns_notify_on_insufficient_data` | false | false | true |
| Burst thresholds | More permissive | Intermediate | Stricter |
| S3 / RDS usage families | Mostly off | On | On |
| Per-resource lists | Empty placeholders | Empty placeholders | Empty placeholders (fill with inventory) |

## Important variables

| Name | Description |
|---|---|
| `account_alias` | Naming prefix segment |
| `environment` | Environment tag |
| `aws_region` | Provider region |
| `create_sns_topic` | Create managed SNS topic + email subscriptions |
| `notification_emails` | Email endpoints for the managed SNS topic |
| `sns_notify_on_ok` / `sns_notify_on_insufficient_data` | Also notify managed SNS on OK / INSUFFICIENT_DATA |
| `alarm_actions` | Extra ARNs merged with the managed SNS topic |
| `cloudtrail_log_group_name` | Existing CloudTrail → Logs group |
| `config_role_arn` | Existing Config service role ARN (required when Config rules are enabled) |
| `enable_*` | Feature toggles per monitoring family (includes network, S3 policy, open SG, log deletion) |
| Threshold / period variables | Tune metric alarm sensitivity |
| `ec2_instance_ids`, `s3_bucket_names`, `rds_db_instance_identifiers` | Optional resource-scoped alarms |

## Outputs

| Name | Description |
|---|---|
| `name_prefix` | Shared resource name prefix |
| `account_id` / `region` | Resolved deployment identity |
| `sns_topic_arn` / `sns_topic_name` | Managed SNS topic (null if disabled) |
| `sns_subscription_emails` | Subscribed email endpoints |
| `effective_alarm_actions` | Final notification ARNs after SNS merge |
| `eventbridge_rule_arns` | EventBridge rule ARNs by key |
| `metric_filter_names` | Metric filter names by key |
| `cloudwatch_alarm_arns` / `cloudwatch_alarm_names` | Flat alarm lists |
| `cloudwatch_alarms_by_type` | Alarms grouped by type |
| `config_rule_arns` / `config_rule_names` | Config rules by key |
| `resources_by_category` | Audit-friendly category summary |

## Cost and noise notes

- Metric filters evaluate every matching log event in the CloudTrail log group; busy accounts can increase CloudWatch Logs and custom metric costs.
- Config managed rules incur Config evaluation charges while the recorder is active.
- Dev defaults intentionally raise some burst thresholds and disable S3/RDS usage families to reduce noise.
- Console login without MFA can be noisy if federation or break-glass workflows do not use MFA; disable `enable_console_security_monitoring` or remove that rule family if needed.
- If Security Hub or GuardDuty already covers overlapping detections, use the `enable_*` flags to avoid duplicate paging.

## Future extensions

- Geo / CIDR allow-list filtering for unusual console login source IPs
- AWS Config Conformance Packs for broader CIS / FSBP coverage
- Severity-tiered SNS topics (warning vs critical) via separate action lists

## Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.5.0` |
| hashicorp/aws | `>= 5.0` |
