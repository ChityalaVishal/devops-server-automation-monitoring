
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_caller_identity" "current" {}

data "aws_instance" "master" {
  instance_id = "i-0685814085f06174f"
}

data "aws_instance" "agent1" {
  instance_id = "i-088c915e529f5b2ba"
}

data "aws_instance" "agent2" {
  instance_id = "i-05997d6379fd8a925"
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "master_instance" {
  value = {
    id         = data.aws_instance.master.id
    private_ip = data.aws_instance.master.private_ip
    type       = data.aws_instance.master.instance_type
  }
}

output "agent1_instance" {
  value = {
    id         = data.aws_instance.agent1.id
    private_ip = data.aws_instance.agent1.private_ip
    type       = data.aws_instance.agent1.instance_type
  }
}

output "agent2_instance" {
  value = {
    id         = data.aws_instance.agent2.id
    private_ip = data.aws_instance.agent2.private_ip
    type       = data.aws_instance.agent2.instance_type
  }
}
