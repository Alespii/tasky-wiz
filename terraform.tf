terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }
  backend "s3" {
    bucket = "tf-state-deployment-alanrdze"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }

  required_version = ">=1.12.2"
}
