data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_secretsmanager_secret_version" "ad_credentials" {
  secret_id = var.ad_admin_password_secret_arn
}
