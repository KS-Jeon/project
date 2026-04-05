resource "aws_directory_service_directory" "this" {
  name        = var.directory_domain_name
  short_name  = upper(split(".", var.directory_domain_name)[0])
  description = var.directory_display_name

  password                             = var.managed_ad_password
  edition                              = "Standard"
  type                                 = "MicrosoftAD"
  enable_sso                           = false
  desired_number_of_domain_controllers = 2

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.directory_subnet_ids
  }

  tags = merge(var.tags, {
    Name = var.directory_display_name
    name = var.directory_display_name
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
