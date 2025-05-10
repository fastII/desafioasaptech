terraform {
  backend "s3" {
    bucket         = "desafio-us-east-1-terraform"
    key            = "ec2/minikube/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
    encrypt        = true
  }
}
