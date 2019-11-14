terraform {
  required_version = ">= 0.12.10"
}

provider "aws" {
  region = "us-east-1"
  # profile = "your-profile-name"
  version = ">= 2.35.0"
}
