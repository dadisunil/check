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
    kms            = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "uniphore-lab-artifacts"
}

# Secure-by-default bucket (what Trivy's AVD-AWS-0086/87/88/91/93/132 checks demand)
resource "aws_kms_key" "artifacts" {
  description         = "uniphore-lab artifacts"
  enable_key_rotation = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.artifacts.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Real Uniphore note: Secrets Manager lives in ONE region; names encode the target region.
resource "aws_secretsmanager_secret" "db" {
  name = "lab/us-east-2/postgres-password"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = "labpass"
}
