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
    from_port   = 80
    to_port     = 80
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
    cidr_blocks = ["0.0.0.0/0"]
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
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              EXTERNAL_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)
              apt-get install apt-transport-https curl gnupg-agent ca-certificates software-properties-common -y
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable"
              apt-get install docker-ce docker-ce-cli containerd.io -y
              systemctl enable docker && sudo systemctl start docker
              curl -sfL https://get.k3s.io | sh -s - server --docker --tls-san $EXTERNAL_IP
              export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              until kubectl get nodes; do sleep 5; done
              kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
              echo -e "alias k=kubectl\n" >> /root/.bash_aliases
              mkdir -p /home/ubuntu/.kube
              cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
              chown ubuntu: -R /home/ubuntu/.kube
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

resource "null_resource" "download_kube_config" {
  provisioner "remote-exec" {
    connection {
      host        = aws_eip.k3s_eip.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/task1")
      timeout     = "10m"
    }

    inline = [
      "echo 'shell connected!'",
      "until [ -f /home/ubuntu/.kube/config ]; do echo 'waiting k3s config...'; sleep 5; done",
      "sed 's/127.0.0.1/${aws_eip.k3s_eip.public_ip}/g' /home/ubuntu/.kube/config > /home/ubuntu/.kube/extconfig"
    ]
  }

  depends_on = [aws_eip.k3s_eip]
}
module "github_runner" {
  source              = "./modules/github_runner"
  github_action_token = var.github_action_token
  github_url          = "https://github.com/sunnes/task1"
  remote_k3s_ip       = aws_eip.k3s_eip.public_ip
}

output "instance_id" {
  description = "instance ID"
  value       = aws_instance.k3s_server.id
}

output "public_ip" {
  description = "public IP"
  value       = aws_instance.k3s_server.public_ip
}
