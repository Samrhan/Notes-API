# Fichier: main.tf (ou versions.tf pour cette partie)

terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Utilise une version compatible 5.x du provider AWS
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region = "eu-west-3" # Région Paris, vous pouvez choisir une autre
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

# Variables pour rendre notre configuration plus flexible
variable "project_name" {
  description = "Nom du projet utilisé pour nommer les ressources."
  type        = string
  default     = "simple-notes-api"
}

variable "dynamodb_table_name" {
  description = "Nom de la table DynamoDB pour les notes."
  type        = string
  default     = "NotesTable"
}