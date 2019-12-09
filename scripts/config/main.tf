provider "aws" {
  region = var.aws_region
  version = "~> 2.3"
}
locals {
  managed_rules = [
    "ELASTICSEARCH_ENCRYPTED_AT_REST",
    "ELASTICSEARCH_IN_VPC_ONLY",
    "ELB_ACM_CERTIFICATE_REQUIRED",
    "ELB_DELETION_PROTECTION_ENABLED",
    "ELB_LOGGING_ENABLED",
    "ENCRYPTED_VOLUMES",
    "EC2_INSTANCE_NO_PUBLIC_IP",
    "EC2_INSTANCE_MANAGED_BY_SSM",
    "INSTANCES_IN_VPC",
    "EC2_SECURITY_GROUP_ATTACHED_TO_ENI",
    "EC2_VOLUME_INUSE_CHECK",
    "EIP_ATTACHED",
    "LAMBDA_CONCURRENCY_CHECK",
    "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED",
    "RESTRICTED_INCOMING_TRAFFIC",
    "INCOMING_SSH_DISABLED",
    "KMS_CMK_NOT_SCHEDULED_FOR_DELETION",
    "DB_INSTANCE_BACKUP_ENABLED",
    "DYNAMODB_AUTOSCALING_ENABLED",
    "DYNAMODB_TABLE_ENCRYPTION_ENABLED",
    "RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
    "RDS_STORAGE_ENCRYPTED",
    "RDS_SNAPSHOTS_PUBLIC_PROHIBITED",
    "REDSHIFT_CLUSTER_CONFIGURATION_CHECK",
    "REDSHIFT_CLUSTER_PUBLIC_ACCESS_CHECK",
    "SAGEMAKER_NOTEBOOK_NO_DIRECT_INTERNET_ACCESS",
    "SAGEMAKER_NOTEBOOK_INSTANCE_KMS_KEY_CONFIGURED",
    "CLOUD_TRAIL_CLOUD_WATCH_LOGS_ENABLED",
    "CLOUD_TRAIL_ENABLED",
    "CLOUD_TRAIL_ENCRYPTION_ENABLED",
    "CLOUDFRONT_VIEWER_POLICY_HTTPS",
    "VPC_DEFAULT_SECURITY_GROUP_CLOSED",
    "VPC_FLOW_LOGS_ENABLED",
    "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS",
    "ACCESS_KEYS_ROTATED",
    "GUARDDUTY_ENABLED_CENTRALIZED",
    "IAM_GROUP_HAS_USERS_CHECK",
    "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS",
    "IAM_ROLE_MANAGED_POLICY_CHECK",
    "IAM_ROOT_ACCESS_KEY_CHECK",
    "IAM_USER_GROUP_MEMBERSHIP_CHECK",
    "IAM_USER_MFA_ENABLED",
    "IAM_USER_NO_POLICIES_CHECK",
    "IAM_USER_UNUSED_CREDENTIALS_CHECK",
    "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS",
    "ROOT_ACCOUNT_HARDWARE_MFA_ENABLED",
    "ROOT_ACCOUNT_MFA_ENABLED",
    "EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK",
    "EFS_ENCRYPTED_CHECK",
    "S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",
    "IAM_PASSWORD_POLICY"
  ]
}
resource "aws_config_configuration_aggregator" "organization" {
  depends_on = ["aws_iam_role_policy_attachment.organization"]

  name = var.org_name

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.con.arn
  }

  tags = {
    Type = "Created by script"
  }
}

resource "aws_config_configuration_recorder" "cr" {
  name     = "config_recorder"
  role_arn = aws_iam_role.con.arn
}

resource "aws_config_configuration_recorder_status" "crstatus" {
  name       = aws_config_configuration_recorder.cr.name
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.dc"]
}

resource "aws_s3_bucket" "b" {
  bucket = "config-bucket"
  versioning {
    mfa_delete = true
    enabled = false
  }
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_config_delivery_channel" "dc" {
  name           = "config-dc"
  s3_bucket_name = aws_s3_bucket.b.bucket
  depends_on     = ["aws_config_configuration_recorder.cr"]
}

resource "aws_iam_role" "con" {
  name = var.config_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "p" {
  name = "awsconfig-example"
  role = aws_iam_role.con.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.b.arn}",
        "${aws_s3_bucket.b.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "organization" {
  role       = aws_iam_role.con.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_organizations_organization" "my_org" {
  aws_service_access_principals = ["config-multiaccountsetup.amazonaws.com"]
  feature_set                   = "ALL"
}

resource "aws_config_organization_managed_rule" "my_org_rules" {
  depends_on = ["aws_organizations_organization.my_org"]
  for_each = toset(local.managed_rules)
  name            = "my_org_rules"
  rule_identifier = each.key
}
