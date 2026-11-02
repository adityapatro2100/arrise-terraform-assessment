provider "aws" {
  region = var.region
}

# The latest AMI makes the example runnable without hardcoding a region-specific
# AMI ID. Production should pin an approved AMI to avoid unplanned replacements.
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "ec2_fleet" {
  source    = "../../modules/ec2"
  ami_id    = data.aws_ami.amazon_linux_2023.id
  instances = var.instances
}
