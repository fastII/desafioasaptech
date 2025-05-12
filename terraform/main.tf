
module "ec2_minikube" {
  source          = "./modules/ec2_minikube"
  instance_name   = "minikube-node"
  instance_type   = "t2.medium"
  key_name        = var.key_name
  public_key_path = var.public_key_path
  private_key_path  = var.private_key_path
  ami_id          = var.ami_id
}

# Envia o chart para a EC2

resource "null_resource" "upload_helm_chart" {
  provisioner "file" {
    source      = "../helm-chart"
    destination = "/home/ec2-user/chart"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = module.ec2_minikube.public_ip
    }
  }

  depends_on = [module.ec2_minikube]
}

# Executa helm install após upload
resource "null_resource" "helm_install" {
  provisioner "remote-exec" {
    inline = [
      "cd /home/ec2-user",
      "helm install myapp ./chart --namespace default"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = module.ec2_minikube.public_ip
    }
  }

  depends_on = [null_resource.upload_helm_chart]
}