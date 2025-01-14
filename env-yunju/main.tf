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

module "yunju_vpc" {
  source                           = "../vpc"
  env_name                         = "yunju"
  cidr                             = "10.3.0.0/16"
  nat_primary_network_interface_id = module.yunju_ec2.nat_primary_network_interface_id
}

module "yunju_sg" {
  source = "../sg"
  vpc_id = module.yunju_vpc.vpc_id
}

module "yunju_ec2" {
  source = "../ec2"

  public_subnets_id  = module.yunju_vpc.public_subnets_id
  private_subnets_id = module.yunju_vpc.private_subnets_id

  bastion_host_sg_id = module.yunju_sg.bastion_host_sg_id
  nat_sg_id          = module.yunju_sg.nat_sg_id
  web_sg_id          = module.yunju_sg.web_sg_id
  app_sg_id          = module.yunju_sg.app_sg_id
}

# elb 모듈 선언
module "yunju_elb" {
  source             = "../elb"
  vpc_id             = module.yunju_vpc.vpc_id
  public_subnets_id  = module.yunju_vpc.public_subnets_id
  web11_ec2_id       = module.yunju_ec2.web11_ec2_id
  web31_ec2_id       = module.yunju_ec2.web31_ec2_id
  private_subnets_id = module.yunju_vpc.private_subnets_id
  app12_ec2_id       = module.yunju_ec2.app12_ec2_id
  app32_ec2_id       = module.yunju_ec2.app32_ec2_id
  app13_ec2_id       = module.yunju_ec2.app13_ec2_id
  app33_ec2_id       = module.yunju_ec2.app33_ec2_id
  web_sg_id          = module.yunju_sg.web_sg_id
}


# WAF 모듈 호출
module "yunju_waf" {
  source            = "../waf"
  alb_arn           = module.yunju_elb.alb_arn # ELB의 ARN을 WAF 모듈에 전달
  web_acl_name      = "waf_web_acl"      # WAF Web ACL 이름
  web_acl_scope     = "REGIONAL"
  allowed_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"] # 허용된 IP 목록
  blocked_ip_ranges = ["192.0.2.0/24"]                      # 차단된 IP 목록
  rate_limit        = 1000                                  # 속도 제한 (1,000 요청/5초)
}