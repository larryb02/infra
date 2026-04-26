# Changelog — bastion

All notable changes to the bastion project infrastructure.

## [Unreleased]

## [1.0.0] - 2026-04-26
### Added
- Initial project structure under projects/bastion
- Terraform: ec2-instance module, SSM-only security group
- S3 remote state with DynamoDB locking (migrated from local state)
- Env-separated tfvars (prod)
