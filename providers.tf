terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # =========================================================================
  # CONFIGURAÇÃO DO BACKEND REMOTO (S3)
  # ATENÇÃO: Deixe este bloco comentado com '#' até que você crie o bucket 
  # fisicamente na AWS usando o comando 'terraform apply'.
  # =========================================================================
  backend "s3" {
    bucket         = "terraform-backend-edmilsonlima-cloud-174990409836-us-east-1-an" # Nome exato do bucket S3
    key            = "dev/terraform.tfstate"            # Caminho e nome do arquivo de estado dentro do bucket
    region         = "us-east-1"                         # Mesma região do seu provider
    encrypt        = true                                # Ativa criptografia nos arquivos de state
    #dynamodb_table = "terraform-state-lock"              # (Opcional) Tabela DynamoDB para evitar travas concorrentes
  }
}

provider "aws" {
  region = "us-east-1"
}
