variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "account_a_id" {
  type    = string
  default = "000000000000"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_a_id))
    error_message = "Account ID must have 12 digits."
  }
}

variable "account_b_id" {
  type    = string
  default = "111111111111"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_b_id))
    error_message = "Account ID must have 12 digits."
  }
}

variable "console_password_pgp_key" {
  type        = string
  description = "PGP public key (base64) or keybase:<name> to encrypt initial console passwords and API key secrets."
}

variable "ecr_repository_name" {
  type    = string
  default = "arrise-ci-app"
}

variable "ecs_cluster_name" {
  type    = string
  default = "arrise-app-cluster"
}

variable "ecs_service_name" {
  type    = string
  default = "arrise-app-service"
}

variable "ecs_task_family" {
  type    = string
  default = "arrise-ci-app"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "Existing ECS task IAM role ARN that ci is allowed to pass."
}

variable "ecs_execution_role_arn" {
  type        = string
  description = "Existing ECS execution IAM role ARN that ci is allowed to pass."
}

variable "artifact_bucket_name" {
  type    = string
  default = "arrise-ci-artifacts-000000000000"
}
