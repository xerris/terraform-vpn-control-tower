data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
  tags = {
    Name = var.subnet_tag
  }
}

data "aws_ec2_transit_gateway" "tg"{
    filter {
    name   = "options.amazon-side-asn"
    values = [var.tg_asn]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attachment" {
  subnet_ids         = data.aws_subnet_ids.subnets.ids
  transit_gateway_id = data.aws_ec2_transit_gateway.tg.id
  vpc_id             = var.vpc_id
}

provider "aws" {
  alias = "first"
  region     = var.region
  profile = var.profile_ic
}


resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "accept-on-interconnect" {
  provider = aws.first
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.attachment.id
  tags = {
    Name = var.tag_accepter
    Side = "Acceptor"
  }
}

data "aws_route_tables" "rts" {
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Name"
    values = [var.rt_name]
  }
}

locals{
  product = setproduct(tolist(data.aws_route_tables.rts.ids), var.cidr_blocks)
}

resource "aws_route" "routes" {
  count                     = length(local.product)
  route_table_id            = element(local.product,count.index)[0]
  destination_cidr_block    = element(local.product,count.index)[1]
  transit_gateway_id = data.aws_ec2_transit_gateway.tg.id
}
