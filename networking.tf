resource "aws_vpc" "terraform_vpc" {
    cidr_block = "100.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

}

resource "aws_subnet" "terraform_public_subnet_1" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = "100.0.0.0/17"
  availability_zone = "us-east-2a"

  tags = {
    "kubernetes.io/cluster/terraform-tasky" = "shared",
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "terraform_private_subnet_1" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = "100.0.128.0/18"
  availability_zone = "us-east-2a"
	tags = {
    "kubernetes.io/cluster/terraform-tasky" = "owned",
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "terraform_public_subnet_2" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = "100.0.192.0/19"	
  availability_zone = "us-east-2b"
  tags = {
    "kubernetes.io/cluster/terraform-tasky" = "owned",
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "terraform_private_subnet_2" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = "100.0.224.0/19"
  availability_zone = "us-east-2b"
  tags = {
    "kubernetes.io/cluster/terraform-tasky" = "owned",
    "kubernetes.io/role/internal-elb" = "1"
  }
}


resource "aws_internet_gateway" "terraform_igw" {
    vpc_id = aws_vpc.terraform_vpc.id
}

resource "aws_eip" "NATEIP" {
  
}

resource "aws_nat_gateway" "terraform_nat" {
    subnet_id = aws_subnet.terraform_public_subnet_1.id
    connectivity_type = "public"
    allocation_id = aws_eip.NATEIP.allocation_id
    
}

resource "aws_route_table" "terraform_PS_RT" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
   }
   route {
    cidr_block = aws_vpc.terraform_vpc.cidr_block
    gateway_id = "local"
   }
}

resource "aws_route_table_association" "PS_association" {
  route_table_id = aws_route_table.terraform_PS_RT.id
  subnet_id = aws_subnet.terraform_public_subnet_1.id
}

resource "aws_route_table_association" "PS_association2" {
  route_table_id = aws_route_table.terraform_PS_RT.id
  subnet_id = aws_subnet.terraform_public_subnet_2.id
}

resource "aws_route_table" "terraform_PrivS1_RT" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terraform_nat.id
   }

   route {
    cidr_block = aws_vpc.terraform_vpc.cidr_block
    gateway_id = "local"
   }

}

resource "aws_route_table_association" "PrivS_association1" {
  route_table_id = aws_route_table.terraform_PrivS1_RT.id
  subnet_id = aws_subnet.terraform_private_subnet_1.id
}

resource "aws_route_table" "terraform_PrivS2_RT" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terraform_nat.id
   }
  route {
    cidr_block = aws_vpc.terraform_vpc.cidr_block
    gateway_id = "local"
   }
}

resource "aws_route_table_association" "PrivS_association2" {
  route_table_id = aws_route_table.terraform_PrivS2_RT.id
  subnet_id = aws_subnet.terraform_private_subnet_2.id
}