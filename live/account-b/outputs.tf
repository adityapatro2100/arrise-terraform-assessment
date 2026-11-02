output "roleC_arn" {
  value = aws_iam_role.roleC.arn
}

output "roleC_bucket_name" {
  value = aws_s3_bucket.roleC_bucket.id
}
