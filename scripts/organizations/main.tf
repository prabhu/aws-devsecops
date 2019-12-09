provider "aws" {
  region = var.aws_region
  version = "~> 2.3"
}
data "aws_organizations_organization" "new_org" {}
resource "aws_organizations_account" "account" {
  name  = var.org_acc_name
  email = var.org_acc_email

  lifecycle {
    ignore_changes = ["role_name"]
  }
  tags = {
    Type = "Created by script"
  }
}

resource "aws_organizations_organization" "new_org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com"
  ]
  enabled_policy_types = [
    aws_organizations_policy.Org_default
  ]
  feature_set = "ALL"
}

resource "aws_organizations_policy" "Org_default" {
  name = var.org_policy_name
  description = "Organization default SCP"
  content = <<CONTENT
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": [
      "lambda:*",
      "cloudformation:*",
      "dynamodb:*",
      "config:*",
      "cloudwatch:*",
      "cloudtrail:*",
      "logs:*",
      "wellarchitected:*",
      "secretsmanager:*",
      "s3:*",
      "iam:*",
      "ec2:*",
      "ecs:*",
      "autoscaling:*",
      "application-autoscaling:*",
      "elasticloadbalancing:*",
      "ecr:*",
      "eks:*"
    ],
    "Resource": "*"
  }
}
CONTENT
}
