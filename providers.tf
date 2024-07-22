terraform {
    required_version = "~> 1.9.2" // allow version 1.9.2, 1.9.3, 1.9.4 ..., dont allow 1.8.xx or 1.10.xx
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.58.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}