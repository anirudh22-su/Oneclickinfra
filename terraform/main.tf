###############################################
# FULL MULTI-REGION TERRAFORM main.tf
# PRIMARY + SECONDARY + PEERING + OUTPUTS
###############################################

terraform {
  backend "s3" {
    bucket         = "oneclick-terraform-state-bucket-anuu-2025"
    key            = "multi-region-postgresql/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "oneclick-terraform-lock-anuu-2025"
    encrypt        = true
  }

  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

###############################################
# PRIMARY REGION VPC
###############################################

resource "aws_vpc" "vpc_a" {
  provider   = aws.primary
  cidr_block = var.vpc_a_cidr
  tags = { Name = "vpc-a" }
}

resource "aws_subnet" "public_a" {
  provider = aws.primary
  vpc_id = aws_vpc.vpc_a.id
  cidr_block = var.public_subnet_a
  map_public_ip_on_launch = true
  availability_zone = "${var.primary_region}a"
  tags = { Name = "public-a" }
}

resource "aws_subnet" "private_a" {
  provider = aws.primary
  vpc_id = aws_vpc.vpc_a.id
  cidr_block = var.private_subnet_a
  availability_zone = "${var.primary_region}a"
  tags = { Name = "private-a" }
}

resource "aws_internet_gateway" "igw_a" {
  provider = aws.primary
  vpc_id   = aws_vpc.vpc_a.id
}

resource "aws_eip" "nat_eip_a" {
  provider = aws.primary
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat_a" {
  provider      = aws.primary
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_a.id
}

resource "aws_route_table" "public_rt_a" {
  provider = aws.primary
  vpc_id = aws_vpc.vpc_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_a.id
  }
}

resource "aws_route_table_association" "pub_assoc_a" {
  provider = aws.primary
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt_a.id
}

resource "aws_route_table" "private_rt_a" {
  provider = aws.primary
  vpc_id   = aws_vpc.vpc_a.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
}

resource "aws_route_table_association" "priv_a_assoc" {
  provider = aws.primary
  subnet_id = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

###############################################
# PRIMARY SECURITY GROUPS
###############################################

resource "aws_security_group" "bastion_sg_a" {
  provider = aws.primary
  vpc_id   = aws_vpc.vpc_a.id
  name     = "bastion-sg-a"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.jenkins_ip_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg_a" {
  provider = aws.primary
  name     = "db-sg-a"
  vpc_id   = aws_vpc.vpc_a.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_a_cidr]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [aws_security_group.bastion_sg_a.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
# PRIMARY EC2
###############################################

data "aws_ami" "ubuntu_a" {
  provider    = aws.primary
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "bastion_a" {
  provider = aws.primary
  ami           = data.aws_ami.ubuntu_a.id
  instance_type = var.bastion_type
  subnet_id     = aws_subnet.public_a.id
  key_name      = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg_a.id]
  tags = { Name = "bastion-a" }
}

resource "aws_instance" "primary_db" {
  provider = aws.primary
  ami           = data.aws_ami.ubuntu_a.id
  instance_type = var.db_type
  subnet_id     = aws_subnet.private_a.id
  key_name      = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.db_sg_a.id]
  associate_public_ip_address = false
  tags = { Name = "db-primary-a" }
}

###############################################
# SECONDARY REGION VPC
###############################################

resource "aws_vpc" "vpc_b" {
  provider   = aws.secondary
  cidr_block = var.vpc_b_cidr
  tags = { Name = "vpc-b" }
}

resource "aws_subnet" "public_b" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_b.id
  cidr_block = var.public_subnet_b
  map_public_ip_on_launch = true
  availability_zone = "${var.secondary_region}a"
  tags = { Name = "public-b" }
}

resource "aws_subnet" "private_b" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_b.id
  cidr_block = var.private_subnet_b
  availability_zone = "${var.secondary_region}a"
  tags = { Name = "private-b" }
}

resource "aws_internet_gateway" "igw_b" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_b.id
}

resource "aws_eip" "nat_eip_b" {
  provider = aws.secondary
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat_b" {
  provider      = aws.secondary
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_b.id
}

resource "aws_route_table" "public_rt_b" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_b.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_b.id
  }
}

resource "aws_route_table_association" "pub_assoc_b" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt_b.id
}

resource "aws_route_table" "private_rt_b" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_b.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
}

resource "aws_route_table_association" "priv_b_assoc" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

###############################################
# SECONDARY REGION SECURITY GROUPS
###############################################

resource "aws_security_group" "bastion_sg_b" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_b.id
  name     = "bastion-sg-b"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.jenkins_ip_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg_b" {
  provider = aws.secondary
  name     = "db-sg-b"
  vpc_id   = aws_vpc.vpc_b.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_b_cidr]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg_b.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
# SECONDARY EC2
###############################################

data "aws_ami" "ubuntu_b" {
  provider    = aws.secondary
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "bastion_b" {
  provider = aws.secondary
  ami           = data.aws_ami.ubuntu_b.id
  instance_type = var.bastion_type
  subnet_id     = aws_subnet.public_b.id
  key_name      = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg_b.id]
  tags = { Name = "bastion-b" }
}

resource "aws_instance" "replica_db" {
  provider = aws.secondary
  ami           = data.aws_ami.ubuntu_b.id
  instance_type = var.db_type
  subnet_id     = aws_subnet.private_b.id
  key_name      = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.db_sg_b.id]
  associate_public_ip_address = false
  tags = { Name = "db-replica-b" }
}

###############################################
# VPC PEERING
###############################################

resource "aws_vpc_peering_connection" "peer_ab" {
  provider     = aws.primary
  vpc_id       = aws_vpc.vpc_a.id
  peer_vpc_id  = aws_vpc.vpc_b.id
  peer_region  = var.secondary_region
  auto_accept  = false
}

resource "aws_vpc_peering_connection_accepter" "peer_accept" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_ab.id
  auto_accept               = true
}

resource "aws_route" "route_a_to_b" {
  provider                   = aws.primary
  route_table_id             = aws_route_table.private_rt_a.id
  destination_cidr_block     = var.vpc_b_cidr
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_ab.id
}

resource "aws_route" "route_b_to_a" {
  provider                   = aws.secondary
  route_table_id             = aws_route_table.private_rt_b.id
  destination_cidr_block     = var.vpc_a_cidr
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer_ab.id
}

###############################################
# OUTPUTS
###############################################

output "bastion_a_public_ip" {
  value = aws_instance.bastion_a.public_ip
}

output "primary_db_private_ip" {
  value = aws_instance.primary_db.private_ip
}

output "bastion_b_public_ip" {
  value = aws_instance.bastion_b.public_ip
}

output "replica_db_private_ip" {
  value = aws_instance.replica_db.private_ip
}
