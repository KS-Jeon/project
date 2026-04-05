locals {
  ad_ingress_rules = {
    dns_tcp = {
      from_port = 53
      to_port   = 53
      protocol  = "tcp"
    }
    dns_udp = {
      from_port = 53
      to_port   = 53
      protocol  = "udp"
    }
    kerberos_tcp = {
      from_port = 88
      to_port   = 88
      protocol  = "tcp"
    }
    kerberos_udp = {
      from_port = 88
      to_port   = 88
      protocol  = "udp"
    }
    ldap_tcp = {
      from_port = 389
      to_port   = 389
      protocol  = "tcp"
    }
    ldap_udp = {
      from_port = 389
      to_port   = 389
      protocol  = "udp"
    }
    ldaps_tcp = {
      from_port = 636
      to_port   = 636
      protocol  = "tcp"
    }
    smb_tcp = {
      from_port = 445
      to_port   = 445
      protocol  = "tcp"
    }
    rpc_tcp = {
      from_port = 135
      to_port   = 135
      protocol  = "tcp"
    }
    dynamic_rpc_tcp = {
      from_port = 49152
      to_port   = 65535
      protocol  = "tcp"
    }
  }
}

resource "aws_security_group" "fsx" {
  name        = var.fsx_security_group_name
  description = "Allow SMB/NFS from on-premises and AD traffic from FSx to Managed AD"
  vpc_id      = var.vpc_id

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
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "DNS UDP to Managed AD"
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "Kerberos TCP to Managed AD"
    from_port       = 88
    to_port         = 88
    protocol        = "tcp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "Kerberos UDP to Managed AD"
    from_port       = 88
    to_port         = 88
    protocol        = "udp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "LDAP TCP to Managed AD"
    from_port       = 389
    to_port         = 389
    protocol        = "tcp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "LDAP UDP to Managed AD"
    from_port       = 389
    to_port         = 389
    protocol        = "udp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "LDAPS to Managed AD"
    from_port       = 636
    to_port         = 636
    protocol        = "tcp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "SMB to Managed AD"
    from_port       = 445
    to_port         = 445
    protocol        = "tcp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "RPC endpoint mapper to Managed AD"
    from_port       = 135
    to_port         = 135
    protocol        = "tcp"
    security_groups = [var.managed_ad_security_group_id]
  }

  egress {
    description     = "Dynamic RPC to Managed AD"
    from_port       = 49152
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.managed_ad_security_group_id]
  }

  tags = merge(var.tags, {
    Name = var.fsx_security_group_name
    name = var.fsx_security_group_name
  })
}

resource "aws_security_group_rule" "ad_from_fsx" {
  for_each = local.ad_ingress_rules

  type                     = "ingress"
  description              = "Allow ${each.key} from FSx ONTAP"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = var.managed_ad_security_group_id
  source_security_group_id = aws_security_group.fsx.id
}

resource "aws_ec2_tag" "managed_ad_security_group_tags" {
  for_each = merge(var.tags, {
    Name = var.managed_ad_security_group_name
    name = var.managed_ad_security_group_name
  })

  resource_id = var.managed_ad_security_group_id
  key         = each.key
  value       = each.value
}
