terraform {
  required_version = ">= 0.12.10"
}

provider "aws" {
  region = var.region
  # profile = "your-profile-name"
  version = ">= 2.35.0"
}
