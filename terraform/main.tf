
module "ec2_minikube" {
  source          = "./modules/ec2_minikube"
  instance_name   = "minikube-node"
  instance_type   = "t2.medium"
  key_name        = var.key_name
  public_key_path = var.public_key_path
  private_key_path  = var.private_key_path
  ami_id          = var.ami_id
}

# Readness para SSH
resource "null_resource" "wait_for_ssh" {
  provisioner "remote-exec" {
    inline = ["echo EC2 ready"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = module.ec2_minikube.public_ip
      timeout     = "2m"
    }
  }

  depends_on = [module.ec2_minikube]
}


# Envia o chart para a EC2

resource "null_resource" "upload_helm_chart" {
  provisioner "file" {
    source      = "helm-chart"
    destination = "/home/ec2-user/chart"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = module.ec2_minikube.public_ip
      timeout     = "3m"
    }
  }

 depends_on = [null_resource.wait_for_ssh]
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