output "state_bucket_arn" {
  value = aws_s3_bucket.state.arn
}

output "lock_table_arn" {
  value = aws_dynamodb_table.tf_locks.arn
}

output "github_runner_role_arn" {
  value = aws_iam_role.github_runner.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
