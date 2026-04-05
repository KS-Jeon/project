resource "aws_security_group" "fsx" {
  name        = local.names.fsx_security_group
  description = "Allow SMB/NFS from on-premises and AD traffic from FSx to Managed AD"
  vpc_id      = module.vpc.vpc_id

  revoke_rules_on_delete = true

  ingress {
    description = "SMB from on-premises"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  ingress {
    description = "NFS TCP from on-premises"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  ingress {
    description = "NFS UDP from on-premises"
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = [var.onprem_cidr]
  }

  egress {
    description     = "DNS TCP to Managed AD"
    from_port       = 53
    to_port         = 53
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "DNS UDP to Managed AD"
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "Kerberos TCP to Managed AD"
    from_port       = 88
    to_port         = 88
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "Kerberos UDP to Managed AD"
    from_port       = 88
    to_port         = 88
    protocol        = "udp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "LDAP TCP to Managed AD"
    from_port       = 389
    to_port         = 389
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "LDAP UDP to Managed AD"
    from_port       = 389
    to_port         = 389
    protocol        = "udp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "LDAPS to Managed AD"
    from_port       = 636
    to_port         = 636
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "SMB to Managed AD"
    from_port       = 445
    to_port         = 445
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "RPC endpoint mapper to Managed AD"
    from_port       = 135
    to_port         = 135
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  egress {
    description     = "Dynamic RPC to Managed AD"
    from_port       = 49152
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_directory_service_directory.managed_ad.security_group_id]
  }

  tags = merge(local.provider_default_tags, {
    Name = local.names.fsx_security_group
    name = local.names.fsx_security_group
  })
}

resource "aws_security_group_rule" "ad_from_fsx" {
  for_each = local.ad_ingress_rules

  type                     = "ingress"
  description              = "Allow ${each.key} from FSx ONTAP"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = aws_directory_service_directory.managed_ad.security_group_id
  source_security_group_id = aws_security_group.fsx.id
}

resource "aws_ec2_tag" "managed_ad_security_group_tags" {
  for_each = merge(local.provider_default_tags, {
    Name = local.names.ad_security_group
    name = local.names.ad_security_group
  })

  resource_id = aws_directory_service_directory.managed_ad.security_group_id
  key         = each.key
  value       = each.value
}
