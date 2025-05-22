resource "aws_key_pair" "default" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "minikube" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.default.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

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


  #  Instala pacotes e Minikube
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y curl conntrack iptables git",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
      # Instala o Minikube e o kubectl
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      "newgrp docker <<EONGROUP\nminikube start --driver=docker\nEONGROUP"
    ]
  }

}




#resource "aws_network_interface_sg_attachment" "attach" {
#  security_group_id    = aws_security_group.minikube_sg.id
#  network_interface_id = aws_instance.minikube.primary_network_interface_id
#  depends_on = [aws_instance.minikube]
#}