variable "region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region for remote state storage and DynamoDB locks."
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform remote state."
}

variable "lock_table_name" {
  type        = string
  default     = "arrise-terraform-locks"
  description = "DynamoDB state-lock table in the same AWS account and region."
}
