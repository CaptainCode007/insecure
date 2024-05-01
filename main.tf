terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 3.0.0"
        }
    }

    backend "s3" {
        bucket         = "terraform-state-mrunal"
        key            = "terraform.tfstate"
        region         = "us-east-1"
       
    }
}

provider "aws" {
    region = var.region
}


