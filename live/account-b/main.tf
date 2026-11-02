provider "aws" {
  region = var.region
}

# Full bucket ownership and cross-account role are created in Account B.
resource "aws_s3_bucket" "roleC_bucket" {
  bucket        = var.role_c_bucket_name
  force_destroy = false

  tags = {
    Name        = var.role_c_bucket_name
    Environment = "assessment"
    Owner       = "platform"
  }
}

resource "aws_s3_bucket_public_access_block" "roleC_bucket" {
  bucket                  = aws_s3_bucket.roleC_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "roleC_bucket" {
  bucket = aws_s3_bucket.roleC_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "roleC_bucket" {
  bucket = aws_s3_bucket.roleC_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Corrected task-5 trust: roleB is an IAM ROLE, not an IAM USER.
# Crucially, this principal is the specific role ARN, not Account A's root.
data "aws_iam_policy_document" "roleC_trust" {
  statement {
    sid     = "TrustOnlyAccountARoleB"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:role/roleB"]
    }
  }
}

resource "aws_iam_role" "roleC" {
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

# Corrected task-5 policy: S3 access is limited to this bucket and its objects.
data "aws_iam_policy_document" "roleC_s3" {
  statement {
    sid       = "OnlyNamedBucket"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.roleC_bucket.arn, "${aws_s3_bucket.roleC_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "roleC_s3" {
  name   = "roleC-named-bucket-only"
  role   = aws_iam_role.roleC.id
  policy = data.aws_iam_policy_document.roleC_s3.json
}
