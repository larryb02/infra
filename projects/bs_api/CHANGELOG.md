# Changelog — bs_api

All notable changes to the bs_api project infrastructure.

## [Unreleased]

## [1.0.0] - 2026-04-26
### Added
- Initial project structure under projects/bs_api
- Terraform: ec2-instance and security-group-http module references
- Env-separated tfvars (prod, dev)
- S3 remote state with DynamoDB locking
- Ansible bootstrap: containerd, nerdctl, certbot via shared roles
