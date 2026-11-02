variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "account_a_id" {
  type    = string
  default = "000000000000"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_a_id))
    error_message = "Account A ID must have 12 digits."
  }
}

variable "role_c_bucket_name" {
  type    = string
  default = "arrise-assessment-rolec-111111111111"
}
