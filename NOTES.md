# Notes

## Task 1 — EC2

The `instances` map in `live/ec2/terraform.tfvars.example` contains all five machines. Each has its own instance type, volume type, root size and key pair. The example uses `gp3`, `gp2`, `standard`, `io1` and `io2`. The module also checks that there are exactly five entries, that those four settings are unique, and that io1/io2 have an IOPS value. Every machine gets `Name`, `Environment` and `Owner` tags. Both outputs are maps keyed by the instance name.

I protected **`payments-core`** because I've treated it as a production instance that shouldn't be replaced accidentally. It uses an `io1` root volume and has `prevent_destroy = true`, so Terraform will reject a destroy or an update that requires replacement. It also keeps its root EBS volume when terminated. This protection applies while the resource remains in Terraform's configuration and state; it isn't a replacement for backups or AWS-side termination protection.

There are two `aws_instance` blocks, not five. Four instances use `for_each`; `payments-core` reads from the *same* map but has its own resource block. Terraform requires a literal value for `prevent_destroy`, so it cannot be conditionally set with `each.key` in a single block.

## Task 2 — Remote state and locking

With local state, two engineers running `apply` from different machines don't share a lock. Each can calculate a plan against an outdated copy of state, and the later run can overwrite or conflict with changes from the other. Local locking only coordinates operations using the same local state directory.

I added an S3 backend and a bootstrap configuration to create the state bucket and DynamoDB lock table. Once both users point to the same S3 state key and lock table, Terraform takes a lock before a state-changing operation. A second run waits or fails to acquire the lock rather than updating state at the same time. The state bucket has versioning, encryption and public access blocked.

DynamoDB locking is deprecated in newer Terraform releases, but it's included because the question explicitly asks for it. The backend also enables `use_lockfile = true` for S3-native locking. Bootstrap starts locally because Terraform can't store its state in a bucket before that bucket exists. Account A and Account B use different backend buckets/keys.

## Task 3 — IAM and cross-account access

Account A has:

- `group1`: `engine` and `ci`, both without console login profiles.
- `group2`: `alex` and `maya`, both with console login profiles and CLI keys. They can assume `roleA` or `roleB`.
- `roleA`: access to non-IAM AWS actions. IAM is explicitly denied; assuming other roles is also denied to avoid an easy route around the IAM restriction.
- `roleB`: only `sts:AssumeRole` against Account B's `roleC`.

Account B has `roleC`, which trusts only Account A's `roleB` ARN. Its S3 policy covers the named bucket and objects under it, not other buckets. The Account A side needs an identity policy allowing the assume-role call; Account B needs a matching trust policy. Both pieces are in the code.

**Would I give `engine` and `ci` IAM access keys in production?** No, not by default. I created IAM users and PGP-encrypted access keys here to match the exercise. For a CI pipeline I would use OIDC federation to obtain short-lived credentials. For a workload I would use an instance profile or an ECS/EKS workload role. People should use IAM Identity Center with MFA. Long-lived keys are harder to rotate and much easier to leak.

**Why trust `roleB` instead of Account A root?** `arn:aws:iam::000000000000:root` in a trust policy effectively delegates trust to the account, not just the root user's session. Account A could give other identities permission to assume the role. Specifying `arn:aws:iam::000000000000:role/roleB` limits the trusted principal to that particular role. It still matters who can assume or administer `roleB` in Account A.

## Task 4 — CI permissions

The custom JSON policy is in `policies/ci-policy.json`, loaded into the `ci` user's inline policy with `templatefile()` so the resource names are configurable.

The CI user can authenticate to ECR and push layers/images only to the named repository; register task-definition revisions only in the given family; update the given ECS service with a task definition from that family; read deployment status; pass only the two existing ECS task/execution roles to ECS; and list/read the build-artifact bucket. `ecr:GetAuthorizationToken` needs `Resource: "*"` because ECR does not support resource-level scoping for that action. `ecs:DescribeTaskDefinition` likewise uses `*`.

I left out ECR repository creation/deletion, ECS service creation/deletion, running arbitrary tasks, changes to other task families, broad IAM operations, passing arbitrary roles, and S3 writes/deletes. Those aren't necessary to push an image, update the existing service and read artifacts. The ECS service, ECR repo, task roles and artifact bucket must already exist. Tagging new task definitions isn't included; that would need an additional scoped permission.

## Task 5 — Both bugs in the snippet

**Trust policy:** `arn:aws:iam::000000000000:user/roleB` identifies an IAM *user*. `roleB` is a *role*, so this doesn't trust the caller it was supposed to trust. The ARN must end in `role/roleB` instead. See `live/account-b/main.tf`.

**Permission policy:** `Action = "s3:*"` with `Resource = "*"` permits S3 actions against anything the role can access. That's not the requirement. The corrected policy restricts resources to the single bucket ARN (`arn:aws:s3:::bucket-name`) and the objects below it (`arn:aws:s3:::bucket-name/*`). Both are needed for bucket-level and object-level S3 operations.

## Checks and assumptions

The sample values are intentionally placeholders. Real `terraform plan`/`apply` requires two AWS accounts, actual networking and key pairs, an available bucket name and existing CI target resources. The CLI configuration has not been applied to AWS. Run `terraform fmt -check -recursive`, `terraform init -backend=false` and `terraform validate` in every root/module before deployment.
