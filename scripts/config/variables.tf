variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-west-1"
}

variable "org_name" {
  description = "Organization name"
  default = "my_org"
}

variable "config_role_name" {
  description = "Config role name"
  default = "my_config_role"
}
