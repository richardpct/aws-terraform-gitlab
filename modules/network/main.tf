data "aws_availability_zones" "available" {}

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc-${var.env}"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw-${var.env}"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.subnet_public)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_public[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet_public-${var.env}-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.subnet_private)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet_private-${var.env}-${count.index}"
  }
}

resource "aws_subnet" "private_gitlab" {
  count             = length(var.subnet_private_gitlab)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_gitlab[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet_private_gitlab-${var.env}-${count.index}"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.subnet_public)
  domain = "vpc"

  tags = {
    Name = "eip_nat-${var.env}-${count.index}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.subnet_public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat_gw-${var.env}-${count.index}"
  }
}

resource "aws_route_table" "route_nat" {
  count  = length(var.subnet_public)
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "default_route-${var.env}-${count.index}"
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "custom_route-${var.env}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.subnet_public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "private_gitlab" {
  count          = length(var.subnet_private_gitlab)
  subnet_id      = aws_subnet.private_gitlab[count.index].id
  route_table_id = aws_route_table.route_nat[count.index].id
}

resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name = "eip_bastion-${var.env}"
  }
}
