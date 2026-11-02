variable "ami_id" {
  description = "Shared, x86_64 Amazon Linux AMI for the five EC2 instances."
  type        = string
}

variable "instances" {
  description = "Single map containing all five instance definitions; payments-core is protected."
  type = map(object({
    instance_type       = string
    root_volume_type    = string
    root_volume_size_gb = number
    root_volume_iops    = optional(number)
    key_name            = string
    subnet_id           = string
    security_group_ids  = list(string)
    environment         = string
    owner               = string
  }))

  validation {
    condition     = length(var.instances) == 5 && contains(keys(var.instances), "payments-core")
    error_message = "Exactly five instances are required, including payments-core."
  }

  validation {
    condition = alltrue([
      length(distinct([for _, item in var.instances : item.instance_type])) == 5,
      length(distinct([for _, item in var.instances : item.root_volume_type])) == 5,
      length(distinct([for _, item in var.instances : item.root_volume_size_gb])) == 5,
      length(distinct([for _, item in var.instances : item.key_name])) == 5
    ])
    error_message = "Instance type, root EBS type, root size and key pair must each be unique across the five instances."
  }

  validation {
    condition = alltrue([
      for _, item in var.instances :
      contains(["gp2", "gp3", "io1", "io2", "standard"], item.root_volume_type)
      && item.root_volume_size_gb >= 8
      && length(trimspace(item.key_name)) > 0
      && length(trimspace(item.environment)) > 0
      && length(trimspace(item.owner)) > 0
      && length(item.security_group_ids) > 0
    ])
    error_message = "Use an EBS boot-compatible type, root size >= 8 GiB, a nonempty key/environment/owner and at least one security group."
  }

  validation {
    condition = alltrue([
      for _, item in var.instances :
      contains(["io1", "io2"], item.root_volume_type)
      ? (item.root_volume_iops != null && coalesce(item.root_volume_iops, 0) >= 100)
      : item.root_volume_iops == null
    ])
    error_message = "io1/io2 need >=100 explicitly provisioned IOPS; other types should omit root_volume_iops."
  }
}
