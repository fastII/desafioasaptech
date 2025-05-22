variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "minikube-key"
  description = "Nome da chave pública existente no AWS EC2"
}

variable "public_key_path" {
  default     = "/keys/minikube-key.pub"
  description = "Caminho local do arquivo .pub"
}

variable "private_key_path" {
  default     = "/keys/minikube-key"
  description = "Caminho da chave privada"
}

variable "ami_id" {
  default     = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 ou Ubuntu para Minikube
  description = "AMI ID compatível com EC2 + Docker"
}

variable "environment" {}



