terraform {
  required_version = ">= 0.12.10"
}

provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  # profile                 = "your-profile-name"
  version = ">= 2.35.0"
}

provider "template" {
  version = ">= 2.1.2"
}
