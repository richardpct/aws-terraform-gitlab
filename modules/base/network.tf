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

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_public_a
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "subnet_public_a-${var.env}"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_public_b
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "subnet_public_b-${var.env}"
  }
}

resource "aws_subnet" "private_gitlab_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_gitlab_a
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "subnet_private_gitlab_a-${var.env}"
  }
}

resource "aws_subnet" "private_gitlab_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_gitlab_b
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "subnet_private_gitlab_b-${var.env}"
  }
}

resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_db_a
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "subnet_private_db_a-${var.env}"
  }
}

resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_private_db_b
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "subnet_private_db_b-${var.env}"
  }
}

resource "aws_eip" "nat_a" {
  vpc = true

  tags = {
    Name = "eip_nat_a-${var.env}"
  }
}

resource "aws_eip" "nat_b" {
  vpc = true

  tags = {
    Name = "eip_nat_b-${var.env}"
  }
}

resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat_gw_a-${var.env}"
  }
}

resource "aws_nat_gateway" "nat_gw_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "nat_gw_b-${var.env}"
  }
}

resource "aws_route_table" "route_nat_a" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_a.id
  }

  tags = {
    Name = "default_route_a-${var.env}"
  }
}

resource "aws_route_table" "route_nat_b" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_b.id
  }

  tags = {
    Name = "default_route_b-${var.env}"
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

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "private_gitlab_a" {
  subnet_id      = aws_subnet.private_gitlab_a.id
  route_table_id = aws_route_table.route_nat_a.id
}

resource "aws_route_table_association" "private_gitlab_b" {
  subnet_id      = aws_subnet.private_gitlab_b.id
  route_table_id = aws_route_table.route_nat_b.id
}

resource "aws_eip" "bastion" {
  vpc = true

  tags = {
    Name = "eip_bastion-${var.env}"
  }
}
