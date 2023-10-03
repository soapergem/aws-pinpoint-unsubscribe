terraform {
  required_version = ">= 0.12.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.35.0"
    }
  }
}

provider "aws" {
  region = var.region
  # profile = "your-profile-name"
}
