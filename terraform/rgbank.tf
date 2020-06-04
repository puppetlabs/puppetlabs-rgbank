# Configure AWS provider
provider "aws" {
  region = var.region
}

# Add SSH key 
resource "aws_key_pair" "public_key" {
  key_name   = "public_key"
  public_key = file(var.public_key)
}

# Allow SSH connections from Puppet
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow ssh and HTTP over ports 22 and 80"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance for development environment
resource "aws_instance" "dev_node" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "public_key"
  security_groups = ["allow_ssh_http"]
  count = var.instance_count
  depends_on = [
    aws_key_pair.public_key,
    aws_security_group.allow_ssh_http
  ]
}
