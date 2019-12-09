output "account_ids" {
  value = data.aws_organizations_organization.new_org.accounts[*].id
}
