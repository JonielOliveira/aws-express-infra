# Define as tags padrão utilizadas em todos os recursos da aplicação
locals {
  default_tags = {
    Project     = var.project_name
    Environment = "universal"
    Owner       = "joniel"
    ManagedBy   = "terraform"
  }
}

# Cria o Security Group com regras para liberar SSH, HTTP e HTTPS
resource "aws_security_group" "api_sg" {
  name        = "${var.project_name}-sg"
  description = "Permitir SSH, HTTP e HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags, {
    Name    = "${var.project_name}-sg"
    Purpose = "security-group"
  })

}

# Default VPC + subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  count = var.enable_ssm ? 1 : 0

  name               = "${var.project_name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume.json
  tags               = local.default_tags
}

data "aws_iam_policy_document" "ssm_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.project_name}-ssm-profile"
  role  = aws_iam_role.ssm_role[0].name
  tags  = local.default_tags
}

# Cria a instância EC2 que hospeda o backend
resource "aws_instance" "api_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = [aws_security_group.api_sg.id]
  subnet_id                   = data.aws_subnets.default.ids[0]
  iam_instance_profile        = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null
  associate_public_ip_address = true

  tags = merge(local.default_tags, {
    Name = "${var.project_name}-ec2",
    Purpose = "application-host"
  })

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y curl git ufw
              ufw allow 22
              ufw allow 80
              ufw allow 443
              yes | ufw enable
              EOF
}

# Cria um Elastic IP
resource "aws_eip" "api_eip" {
  count    = var.create_eip ? 1 : 0
  domain   = "vpc"
  tags = merge(local.default_tags, {
    Name    = "${var.project_name}-eip"
    Purpose = "static-ip"
  })
}

# Associa o EIP à instância EC2
resource "aws_eip_association" "api_eip_assoc" {
  count         = var.create_eip ? 1 : 0
  instance_id   = aws_instance.api_instance.id
  allocation_id = aws_eip.api_eip[0].allocation_id
}

# Cria a zona hospedada no Route 53
resource "aws_route53_zone" "api_main_zone" {
  name = var.domain_name

  tags = merge(local.default_tags, {
    Name    = "${var.project_name}-zone"
    Purpose = "dns-zone"
  })
}

# Registro DNS para o backend: api.meusite.com.br
resource "aws_route53_record" "api_backend" {
  zone_id = aws_route53_zone.api_main_zone.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = var.create_eip ? [aws_eip.api_eip[0].public_ip] : [aws_instance.api_instance.public_ip]
}
