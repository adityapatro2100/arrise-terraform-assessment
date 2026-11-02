# Terraform assessment

Terraform for the five infrastructure and IAM tasks. The EC2 configuration is one module with one input map. Account A and Account B are separate Terraform roots so they can be applied using separate AWS credentials.

## Files

- `modules/ec2/` — reusable EC2 module (five instances, one protected)
- `live/ec2/` — instance configuration and remote backend
- `bootstrap/state/` — S3 state bucket and DynamoDB lock table
- `live/account-a/` — users, groups, roleA, roleB and CI permissions
- `live/account-b/` — roleC and its S3 bucket
- `policies/ci-policy.json` — CI policy, rendered using `templatefile()`
- `NOTES.md` — explanations for the five tasks and the two fixes

## Running it

You need Terraform 1.10+ and AWS credentials for the account you are working in. The placeholder account IDs (`000000000000` and `111111111111`) are from the question, not real deployment targets.

1. Bootstrap state in each AWS account separately:

   ```bash
   cd bootstrap/state
   cp terraform.tfvars.example terraform.tfvars
   # Edit the bucket name, then select the correct AWS profile
   AWS_PROFILE=account-a terraform init
   AWS_PROFILE=account-a terraform plan
   AWS_PROFILE=account-a terraform apply
   ```

   Repeat for Account B with a different bucket name and `AWS_PROFILE=account-b`. Keep the bootstrap state file safe; it starts with local state.

2. Set up the EC2 stack:

   ```bash
   cd live/ec2
   cp terraform.tfvars.example terraform.tfvars
   cp backend.hcl.example backend.hcl
   # Replace the subnet IDs, security groups, key names and backend bucket
   AWS_PROFILE=account-a terraform init -backend-config=backend.hcl
   terraform fmt -check -recursive
   AWS_PROFILE=account-a terraform validate
   AWS_PROFILE=account-a terraform plan
   ```

3. Follow the same `tfvars` / `backend.hcl` steps under `live/account-a` and `live/account-b`. **Apply Account A first**, then Account B. The second account references the ARN of `roleB` from the first. Review each plan before applying.

4. To view the instance outputs after an apply:

   ```bash
   cd live/ec2
   terraform output instance_ids
   terraform output private_ips
   ```

Each Terraform root is independent; run `terraform init` and `terraform validate` in each one. The CI policy refers to an existing ECR repository, ECS service, task roles and artifact bucket; it does not create an application deployment stack.

## Before applying to AWS

Replace the sample account IDs, bucket names, existing network IDs, EC2 key pairs, and PGP public key with real values. Running `apply` creates billable resources, including provisioned-IOPS EBS volumes. The AWS resources have **not** been deployed as part of this submission.
