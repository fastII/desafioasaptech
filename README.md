# desafioasaptech #

No desafio proposto pela ASAPTECH a ideia era criar um ambiente ec2 via Terraform e provisionar um ambiente kubernetes no qual escolhemos o minikube por se tratar de uma versão leve e confiável para este desafio. A ideia foi montar os blocos necessários para o provisionamento da EC2 juntamente com o bloco inline para instalar os recursos necessários:

* Docker
* Minikube
* Helm

  No desafio foi falado que precisaríamos guardar o statefiles .tf em um bucket, este bucket foi provisionado com o nome  desafio-us-east-1-terraform e fomos além. Configuramos o LockID do DynamoDB, isto é uma melhoria em provisionamentos terraform para a Cloud, ou seja, travamos em lock alterações simultâneas, segue imagem em anexo:

  ****<img width="470" alt="image" src="https://github.com/user-attachments/assets/984f9643-7931-4100-a19a-d3596d86fbdc" />

  Segue abaixo o .tf para criar o bucket e a tabela do DynamoDB

main.tf

resource "aws_s3_bucket" "bucketstate" {
  bucket = var.bucket_name


  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# Habilitando o versionamento (NOVO FORMATO)
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucketstate.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = var.dynamodb_table_name
  hash_key = var.hash_key
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
}

variables.tf
variable "bucket_name" {
  default     = "desafio-us-east-1-terraform"
  description = "The name of the bucket to create"
}
variable "bucket_region" {
  default     = "us-east-1"
  description = "The region to create the bucket in"
}
#variable "bucket_versioning" {
#  default     = true
#  description = "Enable versioning for the S3 bucket"
#}
variable "dynamodb_table_name" {
  default     = "terraform-state-lock-dynamodb"
  description = "The name of the DynamoDB table to create for state locking"
}

variable "hash_key" {
  default     = "LockID"
  description = "The hash key for the DynamoDB table"
  
}



* Temos a seguinte estrutura de diretórios nesse repositório

  terraform/
├── main.tf               
├── variables.tf
├── modules/
│   └── ec2_minikube/
│       ├── main.tf      
│       ├── variables.tf
│       └── outputs.tf
├── helm-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/

Pode notar na estrutura acima que criamos o módulo EC2, isto também faz parte das boas práticas do Terraform, pois os módulos podem ser reutilizados quando necessários.

<img width="425" alt="image" src="https://github.com/user-attachments/assets/48cf235e-b1cb-4e86-8a5b-f7b6ecc83e7a" />

Fomos além da ideia de subir via terraform, para este desafio criamos uma pipeline para realizar todo o fluxo de provisionamento com a role-to-assume identity provider do github, podendo ser encontrado nessa documentação 
https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/. A ideia foi criar todo o ambiente e posteriormente validar com acesso via ssh. Criamos as chaves .pub através de comando ssh interagindo com o actions runner do github.

Segue a estrutura

ame: Deploy EC2 + Minikube via Terraform

on:
  push:
    branches:
      - main  
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read  

    env:
      TF_VAR_instance_name: minikube-node
      TF_VAR_instance_type: t3.medium
      TF_VAR_ami_id: ami-0c2b8ca1dad447f8a # Amazon Linux 2
      SSH_KEY_NAME: minikube-key
      AWS_REGION: us-east-1
      aws-statefile-s3-bucket: desafio-us-east-1-terraform
      aws-lock-dynamodb-table: terraform-state-lock-dynamo 

    steps:
      - name: Checkout repo
        uses: actions/checkout@v3
        
     # Setup Terraform
     
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.3

     # Gerar chaves ssh

      - name: Generate SSH Key
        run: |
          mkdir -p terraform/keys
          ssh-keygen -t rsa -b 4096 -f terraform/keys/${SSH_KEY_NAME} -N ""
          
     # Criação Envs 
     
      - name: Set Terraform ENV vars
        run: |
          echo "TF_VAR_key_name=${SSH_KEY_NAME}" >> $GITHUB_ENV
          echo "TF_VAR_public_key_path=keys/${SSH_KEY_NAME}.pub" >> $GITHUB_ENV
          echo "TF_VAR_private_key_path=keys/${SSH_KEY_NAME}" >> $GITHUB_ENV

          
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.ROLE_TO_ASSUME }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          audience: sts.amazonaws.com
          aws-region: ${{ env.AWS_REGION }}

      - name: Initialize Terraform
        working-directory: terraform
        run: terraform init

      - name: Terraform Plan
        working-directory: terraform
        run: terraform plan

      - name: Terraform Apply
        working-directory: terraform
        run: terraform apply -auto-approve

      - name: Output EC2 IP
        working-directory: terraform
        run: terraform output public_ip

Passamos a criação das chaves .pub para que o agent conseguisse acessar a máquina via ssh e rodar os comandos para instalação dos pacotes necessários pós provisionamento, além tentamos subir os arquivos da estrutura do helm chart para a máquina, mas batemos em alguns impecilhos e por falta de tempo resolvemos fazer o upload via ssh.

No desafio proposto tivemos que corrigir as devidas falhas nos manifestos do helm, são eles:

Erros encontrados no arquivos de manifestos:

1. YAML inválido por problemas de indentação no deployment.yaml
O campo spec de template está mal indentado.

O campo containers está dentro de spec errado (está sob metadata).

imagem fixa no arquivo deployment


→ Isso não deve ser hardcoded num Helm template. Deve vir de values.yaml.

Como diferencial no desafio foi proposto que deixasse o helm como um template podendo ser utilizado por qualquer imagem

✅ Resultado final
O chart agora é reutilizável para qualquer imagem, basta mudar image.repository e image.tag no values.yaml.

<img width="562" alt="image" src="https://github.com/user-attachments/assets/ce2e0226-cb3a-4065-8bd8-35bcc7ad4ff6" />

Por fim segue o ambiente provisionado na ec2 conforme solicitado


<img width="410" alt="image" src="https://github.com/user-attachments/assets/deccc915-2ab1-42af-9b04-2577928a271e" />

<img width="529" alt="image" src="https://github.com/user-attachments/assets/195a29a6-14e5-4666-9e17-96c5ac56add3" />

<img width="824" alt="image" src="https://github.com/user-attachments/assets/fae6a729-c388-4610-92a7-8dda69762a31" />

<img width="428" alt="image" src="https://github.com/user-attachments/assets/f064baca-35bb-4793-928d-09a5ee899572" />

Por fim fiz um exec ssh no po para validar o serviço no ar, segue abaixo

<img width="611" alt="image" src="https://github.com/user-attachments/assets/1b219985-0057-45f4-a23e-26c7decf365a" />

















