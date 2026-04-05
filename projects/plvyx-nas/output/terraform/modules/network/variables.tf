variable "name_vpc" {
  description = "VPC name tag."
  type        = string
}

variable "name_route_table" {
  description = "Private route table name tag."
  type        = string
}

variable "name_vpn_gateway" {
  description = "Virtual private gateway name tag."
  type        = string
}

variable "name_customer_gateway" {
  description = "Customer gateway name."
  type        = string
}

variable "name_vpn_connection" {
  description = "VPN connection name."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
}

variable "private_subnet_specs" {
  description = "Private subnet definitions."
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}

variable "customer_gateway_bgp_asn" {
  description = "Customer gateway BGP ASN."
  type        = number
}

variable "onprem_public_ip" {
  description = "On-premises customer gateway public IP."
  type        = string
}

variable "onprem_cidr" {
  description = "On-premises internal CIDR."
  type        = string
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
}
