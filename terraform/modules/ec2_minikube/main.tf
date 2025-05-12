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

  #  SSH Connection
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  # Envia o Helm chart local para a EC2
  provisioner "file" {
    source      = "../helm-chart"
    destination = "/home/ec2-user/chart"
  }

  #  Instala pacotes e Minikube
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y curl conntrack iptables git",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
      # Install Minikube and kubectl
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      # Install Helm
      "curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      "newgrp docker <<EONGROUP\nminikube start --driver=docker\nEONGROUP"
    ]
  }

  #  Executa helm install com o chart enviado
  provisioner "remote-exec" {
    inline = [
      "cd /home/ec2-user",
      "helm install myapp ./chart --namespace default"
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
