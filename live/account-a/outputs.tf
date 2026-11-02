output "roleA_arn" {
  value = aws_iam_role.roleA.arn
}

output "roleB_arn" {
  value = aws_iam_role.roleB.arn
}

output "console_passwords_pgp_encrypted" {
  description = "Encrypted initial console passwords; decrypt with your private PGP key."
  value       = { for name, login in aws_iam_user_login_profile.console : name => login.encrypted_password }
  sensitive   = true
}

output "access_key_ids" {
  description = "Non-secret key IDs only; key secrets are stored PGP-encrypted; deliver and rotate them securely."
  value = merge(
    { for name, key in aws_iam_access_key.programmatic : name => key.id },
    { for name, key in aws_iam_access_key.console_cli : name => key.id }
  )
}

output "access_key_secrets_pgp_encrypted" {
  description = "PGP-encrypted key secrets only; decrypt using the matching private key."
  value = merge(
    { for name, key in aws_iam_access_key.programmatic : name => key.encrypted_secret },
    { for name, key in aws_iam_access_key.console_cli : name => key.encrypted_secret }
  )
  sensitive = true
}
