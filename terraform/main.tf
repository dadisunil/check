# Infra-as-code practice against LocalStack (fake AWS): S3 + Secrets Manager.
# Start LocalStack first:  docker run -d --name localstack -p 4566:4566 localstack/localstack
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region                      = "us-east-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  endpoints {
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "uniphore-lab-artifacts"
}

# Real Uniphore note: Secrets Manager lives in ONE region; names encode the target region.
resource "aws_secretsmanager_secret" "db" {
  name = "lab/us-east-2/postgres-password"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = "labpass"
}
