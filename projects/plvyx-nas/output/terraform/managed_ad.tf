resource "aws_directory_service_directory" "managed_ad" {
  name        = var.directory_domain_name
  short_name  = upper(split(".", var.directory_domain_name)[0])
  description = local.names.managed_ad

  password                             = local.managed_ad_password
  edition                              = "Standard"
  type                                 = "MicrosoftAD"
  enable_sso                           = false
  desired_number_of_domain_controllers = 2

  vpc_settings {
    vpc_id = module.vpc.vpc_id
    subnet_ids = [
      module.vpc.private_subnets[1],
      module.vpc.private_subnets[2],
    ]
  }

  tags = merge(local.provider_default_tags, {
    Name = local.names.managed_ad
    name = local.names.managed_ad
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
