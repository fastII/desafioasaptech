terraform {
  backend "s3" {
    bucket         = "desafio-us-east-1-terraform"
    key            = "terraform/desafioasaptech/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
    encrypt        = true
  }
}
