terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
  }
}

provider "aws" {
  profile = "terraform-user"
}

module "ewunng_vpc" {
  source                           = "../vpc"
  env_name                         = "ewunng"
  cidr                             = "10.1.0.0/16"
  nat_primary_network_interface_id = module.ewunng_ec2.nat_primary_network_interface_id
}

module "ewunng_sg" {
  source = "../sg"
  vpc_id = module.ewunng_vpc.vpc_id
}

module "ewunng_ec2" {
  source = "../ec2"

  public_subnets_id  = module.ewunng_vpc.public_subnets_id
  private_subnets_id = module.ewunng_vpc.private_subnets_id

  bastion_host_sg_id = module.ewunng_sg.bastion_host_sg_id
  nat_sg_id          = module.ewunng_sg.nat_sg_id
  web_sg_id          = module.ewunng_sg.web_sg_id
  app_sg_id          = module.ewunng_sg.app_sg_id
}

module "ewunng_s3" {
  source            = "../S3"
  bucket_name       = "project-team2-bucket"
  kms_master_key_id = "arn:aws:kms:region:account-id:key/key-id"
}

module "ewunng_rds" {
  source             = "../rds"
  env_name           = module.ewunng_vpc.env_name
  private_subnets    = module.ewunng_vpc.private_subnets_id
  db_sg_id           = module.ewunng_sg.db_sg_id
  db_name            = "team2db"
  db_master_username = "admin"
  db_master_password = "project1234"
}