resource "aws_kms_key" "fsx" {
  description             = local.names.kms_key
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAccountAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowFSxServiceUsage"
        Effect = "Allow"
        Principal = {
          Service = "fsx.amazonaws.com"
        }
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ListGrants",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
            "kms:ViaService"    = "fsx.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = merge(local.provider_default_tags, {
    Name = local.names.kms_key
    name = local.names.kms_key
  })
}

resource "aws_kms_alias" "fsx" {
  name          = "alias/${local.names.kms_key}"
  target_key_id = aws_kms_key.fsx.key_id
}
