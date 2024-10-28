provider "aws" {
  region = var.region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

terraform {
  backend "s3" {
    bucket         = "tf-x"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "tf-x"
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "aws_key_pair" "account" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "allow_to_k3s" {
  name_prefix = "allow_to_k3s"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["90.190.100.0/22"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k3s_server" {
  ami           = "ami-08eb150f611ca277f" # Ubuntu Server 24.04 LTS
  instance_type = var.instance_type
  key_name      = aws_key_pair.account.key_name

  security_groups = [aws_security_group.allow_to_k3s.name]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              curl -sfL https://get.k3s.io | sh -s - server --tls-san $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
              export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              until kubectl get nodes; do sleep 2; done
              kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
              echo -e "alias k=kubectl\n" >> /root/.bash_aliases
              
              EOF

  tags = {
    Name = "k3s_server"
  }
}

resource "aws_eip" "k3s_eip" {
  instance = aws_instance.k3s_server.id
  domain   = "vpc"
}


resource "cloudflare_record" "a_direct_record" {
  zone_id         = var.cloudflare_zone_id
  name            = format("%s.%s", "task", var.cloudflare_domain)
  type            = "A"
  content         = aws_eip.k3s_eip.public_ip
  ttl             = 60
  proxied         = false
  count           = 1
  allow_overwrite = true
}

resource "cloudflare_record" "a_wld_record" {
  zone_id         = var.cloudflare_zone_id
  name            = format("%s.%s", "*.task", var.cloudflare_domain)
  type            = "A"
  content         = aws_eip.k3s_eip.public_ip
  ttl             = 60
  proxied         = false
  count           = 1
  allow_overwrite = true

  depends_on = [aws_eip.k3s_eip]
}

module "github_runner" {
  source              = "./modules/github_runner"
  kubeconfig          = "/etc/rancher/k3s/k3s.yaml"
  github_action_token = var.github_action_token
  github_repo_url     = "https://github.com/sunnes/task1"
}

output "instance_id" {
  description = "instance ID"
  value       = aws_instance.k3s_server.id
}

output "public_ip" {
  description = "public IP"
  value       = aws_instance.k3s_server.public_ip
}
