provider "aws" {
  region = var.region
}

locals {
  programmatic_users = toset(["engine", "ci"])
  console_users      = toset(["alex", "maya"])
  all_users          = setunion(local.programmatic_users, local.console_users)
}

resource "aws_iam_group" "group1" {
  name = "group1"
}

resource "aws_iam_group" "group2" {
  name = "group2"
}

resource "aws_iam_user" "users" {
  for_each = local.all_users
  name     = each.key
  path     = "/"
}

resource "aws_iam_group_membership" "group1" {
  name  = "group1-programmatic-members"
  group = aws_iam_group.group1.name
  users = [for name in sort(tolist(local.programmatic_users)) : aws_iam_user.users[name].name]
}

resource "aws_iam_group_membership" "group2" {
  name  = "group2-human-members"
  group = aws_iam_group.group2.name
  users = [for name in sort(tolist(local.console_users)) : aws_iam_user.users[name].name]
}

# Assessment-only credentials: store Terraform state securely and never print
# access-key secrets. Production uses workload roles, OIDC or Identity Center.
resource "aws_iam_access_key" "programmatic" {
  for_each = local.programmatic_users
  user     = aws_iam_user.users[each.key].name
  pgp_key  = var.console_password_pgp_key
}

resource "aws_iam_access_key" "console_cli" {
  for_each = local.console_users
  user     = aws_iam_user.users[each.key].name
  pgp_key  = var.console_password_pgp_key
}

resource "aws_iam_user_login_profile" "console" {
  for_each                = local.console_users
  user                    = aws_iam_user.users[each.key].name
  pgp_key                 = var.console_password_pgp_key
  password_reset_required = true
}

data "aws_iam_policy_document" "human_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        for name in sort(tolist(local.console_users)) : aws_iam_user.users[name].arn
      ]
    }
  }
}

resource "aws_iam_role" "roleA" {
  name               = "roleA"
  assume_role_policy = data.aws_iam_policy_document.human_trust.json
  description        = "Administrator for non-IAM AWS services."
}

data "aws_iam_policy_document" "non_iam_admin" {
  statement {
    sid           = "AllowAllOtherServices"
    effect        = "Allow"
    not_actions   = ["iam:*", "sts:AssumeRole"]
    resources     = ["*"]
  }

  statement {
    sid       = "ExplicitlyDenyIam"
    effect    = "Deny"
    actions   = ["iam:*", "sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "roleA" {
  name   = "non-iam-admin"
  role   = aws_iam_role.roleA.id
  policy = data.aws_iam_policy_document.non_iam_admin.json
}

resource "aws_iam_role" "roleB" {
  name               = "roleB"
  assume_role_policy = data.aws_iam_policy_document.human_trust.json
  description        = "Only permitted to assume Account B roleC."
}

data "aws_iam_policy_document" "roleB_assume_C" {
  statement {
    sid       = "AssumeOnlyRoleC"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${var.account_b_id}:role/roleC"]
  }
}

resource "aws_iam_role_policy" "roleB" {
  name   = "assume-roleC-only"
  role   = aws_iam_role.roleB.id
  policy = data.aws_iam_policy_document.roleB_assume_C.json
}

# Human users authenticate with console credentials or their CLI access keys,
# then explicitly assume one of these two roles. This group has no other grant.
data "aws_iam_policy_document" "group2_assume_roles" {
  statement {
    sid       = "AssumeEntryRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.roleA.arn, aws_iam_role.roleB.arn]
  }

  # These two users must reset their generated console passwords at first login.
  statement {
    sid       = "ChangeOwnConsolePassword"
    effect    = "Allow"
    actions   = ["iam:ChangePassword"]
    resources = ["arn:aws:iam::${var.account_a_id}:user/&{aws:username}"]
  }

  statement {
    sid       = "ReadAccountPasswordPolicy"
    effect    = "Allow"
    actions   = ["iam:GetAccountPasswordPolicy"]
    resources = ["*"]
  }
}

resource "aws_iam_group_policy" "group2" {
  name   = "group2-assume-entry-roles"
  group  = aws_iam_group.group2.name
  policy = data.aws_iam_policy_document.group2_assume_roles.json
}

# Only 'ci' gets the ECR/ECS/S3 deployment permissions (not engine/group1).
resource "aws_iam_user_policy" "ci" {
  name   = "ci-deploy-minimum"
  user   = aws_iam_user.users["ci"].name
  policy = templatefile("${path.module}/../../policies/ci-policy.json", {
    region                  = var.region
    account_a_id            = var.account_a_id
    ecr_repository_name     = var.ecr_repository_name
    ecs_cluster_name        = var.ecs_cluster_name
    ecs_service_name        = var.ecs_service_name
    ecs_task_family         = var.ecs_task_family
    ecs_task_role_arn       = var.ecs_task_role_arn
    ecs_execution_role_arn  = var.ecs_execution_role_arn
    artifact_bucket_name    = var.artifact_bucket_name
  })
}
