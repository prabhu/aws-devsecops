variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-west-1"
}

variable "org_acc_name" {
  description = "Organization account name"
  default = "my_new_account"
}

variable "org_acc_email" {
  description = "Organization account email"
  default = "email@example.com"
}

variable "org_policy_name" {
  description = "Organization service control policy name"
  default = "Org_default_policy"
}
