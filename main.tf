
provider "aws" {
    region = var.current_region
}

resource "aws_vpc" "assignmentvpc" {
  cidr_block       = var.cidr_block_map["cidr_vpc"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "csye6225-vpc"
  }
}

resource "aws_subnet" "subnet1" {
    cidr_block = var.cidr_block_map["cidr1"]
    vpc_id     = aws_vpc.assignmentvpc.id
    availability_zone = var.a_zones_subnet_map["zone1"]
    map_public_ip_on_launch = true
    tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
    cidr_block = var.cidr_block_map["cidr2"]
    vpc_id     = aws_vpc.assignmentvpc.id
    availability_zone = var.a_zones_subnet_map["zone2"]
    map_public_ip_on_launch = true
  tags = {
    Name = "subnet-2"
  }
}

resource "aws_subnet" "subnet3" {
    cidr_block = var.cidr_block_map["cidr3"]
    vpc_id     = aws_vpc.assignmentvpc.id
    availability_zone = var.a_zones_subnet_map["zone3"]
    map_public_ip_on_launch = true

  tags = {
    Name = "subnet-3"
  }
}

resource "aws_internet_gateway" "i_gateway" {
  vpc_id = aws_vpc.assignmentvpc.id

  tags = {
    Name = "i_gateway"
  }
}

resource "aws_route_table" "r_table" {
  vpc_id = aws_vpc.assignmentvpc.id



  route {
    cidr_block = var.cidr_block_map["cidr_route"]
    gateway_id = aws_internet_gateway.i_gateway.id
  }

  tags = {
    Name = "r_table"
  }
}


resource "aws_route_table_association" "rt_association_1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r_table.id
}

resource "aws_route_table_association" "rt_association_2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r_table.id
}

resource "aws_route_table_association" "rt_association_3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.r_table.id
}
