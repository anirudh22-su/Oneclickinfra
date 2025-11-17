variable "primary_region"  { default = "us-east-1" }
variable "secondary_region" { default = "us-west-2" }

variable "vpc_a_cidr"        { default = "10.20.0.0/16" }
variable "public_subnet_a"   { default = "10.20.1.0/24" }
variable "private_subnet_a"  { default = "10.20.2.0/24" }

variable "vpc_b_cidr"        { default = "10.30.0.0/16" }
variable "public_subnet_b"   { default = "10.30.1.0/24" }
variable "private_subnet_b"  { default = "10.30.2.0/24" }

variable "ssh_key_name" { default = "oneclick-key" }
variable "jenkins_ip_cidr" { default = "0.0.0.0/0" }

variable "bastion_type" { default = "t3.micro" }
variable "db_type" { default = "t3.small" }
