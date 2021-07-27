#transit gateway
resource "aws_ec2_transit_gateway" "transit-gateway" {
  description = "project Transit Gateway"

}

data "aws_organizations_organization" "org" {}

output "org"{
  value = data.aws_organizations_organization.org
}

resource "aws_ram_resource_share" "shared" {
  name = "transit-gateway-share"
  allow_external_principals = true
}

resource "aws_ram_resource_association" "example" {
  resource_arn       = aws_ec2_transit_gateway.transit-gateway.arn
  resource_share_arn = aws_ram_resource_share.shared.arn
}

resource "aws_ram_principal_association" "association" {
  count = length(var.ou_list)
  principal          =  var.ou_list[count.index]
  resource_share_arn = aws_ram_resource_share.shared.arn
}

data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attachment-vpc" {
  subnet_ids         = data.aws_subnet_ids.subnets.ids
  transit_gateway_id = aws_ec2_transit_gateway.transit-gateway.id
  vpc_id             = var.vpc_id
}


resource "aws_customer_gateway" "customer-gateway" {
  bgp_asn    = 65500
  ip_address = "172.0.0.1"
  type       = "ipsec.1"
  tags = {
  Name = "project-customer-gateway"
  }
}

resource "aws_vpn_connection" "example" {
  customer_gateway_id = aws_customer_gateway.customer-gateway.id
  transit_gateway_id  = aws_ec2_transit_gateway.transit-gateway.id
  type                = aws_customer_gateway.customer-gateway.type
}