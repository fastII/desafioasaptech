
module "ec2_minikube" {
  source          = "../terraform/modules/ec2_minikube"
  instance_name   = "minikube-node"
  instance_type   = "t2.medium"
  key_name        = var.key_name
  public_key_path = var.public_key_path
  ami_id          = var.ami_id
}
