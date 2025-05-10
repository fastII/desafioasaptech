resource "aws_key_pair" "default" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "minikube" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.default.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.minikube_sg.id]

  tags = {
    Name = var.instance_name
  }

  # ✅ bloco connection fora do provisioner
  connection {
    type        = "ssh"
    user        = "ec2-user" # ou "ubuntu"
    private_key = file("terraform/keys/minikube-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y curl conntrack iptables",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "newgrp docker <<EONGROUP\nminikube start --driver=docker\nEONGROUP"
    ]
  }
}


resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
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

data "aws_vpc" "default" {
  default = true
}

#resource "aws_network_interface_sg_attachment" "attach" {
#  security_group_id    = aws_security_group.minikube_sg.id
#  network_interface_id = aws_instance.minikube.primary_network_interface_id
#}
