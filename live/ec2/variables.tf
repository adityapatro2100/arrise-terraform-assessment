variable "region" {
  type        = string
  description = "AWS region for the instance fleet."
  default     = "ap-south-1"
}

variable "instances" {
  description = "All five EC2 instances are supplied through this single map."
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
}
