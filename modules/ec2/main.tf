locals {
  standard_instances = { for name, spec in var.instances : name => spec if name != "payments-core" }
  protected_instance = var.instances["payments-core"]
}

# One for_each handles four instances; all settings come from the one variable.
resource "aws_instance" "standard" {
  for_each = local.standard_instances

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = each.value.security_group_ids
  associate_public_ip_address = false

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size_gb
    iops                  = each.value.root_volume_iops
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name        = each.key
    Environment = each.value.environment
    Owner       = each.value.owner
  }
}

# Terraform lifecycle flags must be literals. A separate resource block is
# required to protect only payments-core, rather than the other four instances.
resource "aws_instance" "protected" {
  ami                         = var.ami_id
  instance_type               = local.protected_instance.instance_type
  key_name                    = local.protected_instance.key_name
  subnet_id                   = local.protected_instance.subnet_id
  vpc_security_group_ids      = local.protected_instance.security_group_ids
  associate_public_ip_address = false

  root_block_device {
    volume_type           = local.protected_instance.root_volume_type
    volume_size           = local.protected_instance.root_volume_size_gb
    iops                  = local.protected_instance.root_volume_iops
    encrypted             = true
    delete_on_termination = false
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name        = "payments-core"
    Environment = local.protected_instance.environment
    Owner       = local.protected_instance.owner
  }

  lifecycle {
    prevent_destroy = true
  }
}
