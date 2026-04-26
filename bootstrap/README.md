# Bootstrap

One-time account-level setup. Creates the S3 state bucket, DynamoDB lock table, GitHub OIDC provider, and the IAM role used by all CI runs.

**Never run by CI.** Apply manually when setting up a new AWS account.

## Prerequisites

- AWS CLI configured with credentials that can create S3, DynamoDB, IAM, and OIDC resources
- Terraform installed

## Apply

```bash
cd bootstrap/terraform

terraform init

terraform apply \
  -var="github_repo=larryb02/infra"
```

The `terraform.tfstate` file produced here contains no secrets — only resource IDs (ARNs, bucket names). Commit it or store it somewhere safe. If lost, `terraform import` can recover it.

## After applying

1. Copy the `github_runner_role_arn` output and store it as a GitHub secret named `AWS_GITHUB_RUNNER_ROLE`.
2. All project CI workflows will now be able to assume that role via OIDC.

## State migration note

If the S3 bucket already exists (created manually), import it before applying:

```bash
terraform import aws_s3_bucket.state lkb-main-s3-bucket
```
