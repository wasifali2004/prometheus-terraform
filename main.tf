# This script will create Prometheus, Grafana, Alertamanger and some more resources
provider "aws" {
  region = "ap-south-1"
}


data "aws_availability_zones" "available" {}


resource "aws_vpc" "hosting_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Hosting-VPC"
  }
}

# Create a Public Subnet in the first available AZ
resource "aws_subnet" "hosting_subnet" {
  vpc_id                  = aws_vpc.hosting_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]  # Picks the first available AZ

  tags = {
    Name = "Hosting-Public-1"
  }
}


resource "aws_internet_gateway" "hosting_igw" {
  vpc_id = aws_vpc.hosting_vpc.id

  tags = {
    Name = "Hosting-IGW"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hosting_vpc.id

  tags = {
    Name = "Hosting-Public-RT"
  }
}


resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hosting_igw.id
}


resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.hosting_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_security_group" "open_sg" {
  vpc_id = aws_vpc.hosting_vpc.id

  # Allow all inbound traffic (Not recommended for production)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Open-SG"
  }
}


resource "aws_instance" "Prometheus" {
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.medium"
  key_name               = "testing-dev-1"
  subnet_id              = aws_subnet.hosting_subnet.id
  vpc_security_group_ids = [aws_security_group.open_sg.id]

  tags = {
    Name = "Prometheus-server"
  }
}

resource "aws_instance" "Grafana" {
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.medium"
  key_name               = "testing-dev-1"
  subnet_id              = aws_subnet.hosting_subnet.id
  vpc_security_group_ids = [aws_security_group.open_sg.id]

  tags = {
    Name = "Grafana-Server"
  }
}

resource "aws_instance" "Alert-Manager" {
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.medium"
  key_name               = "testing-dev-1"
  subnet_id              = aws_subnet.hosting_subnet.id
  vpc_security_group_ids = [aws_security_group.open_sg.id]

  tags = {
    Name = "Alert-Manager-server"
  }
}

# Outputs
output "Prometheus_public_ip" {
  value = aws_instance.Prometheus.public_ip
}

output "Grafana_public_ip" {
  value = aws_instance.Grafana.public_ip
}

output "Alert_Manager_public_ip" {
  value = aws_instance.Alert-Manager.public_ip
}