# Changelog — cluster

All notable changes to the cluster project infrastructure.

## [Unreleased]

## [1.0.0] - 2026-04-26
### Added
- Initial project structure under projects/cluster
- Terraform: ec2-instance module for server and agent nodes
- Env-separated tfvars (prod: t2.medium server; dev: t2.micro)
- S3 remote state with DynamoDB locking
- Ansible bootstrap: k3s_server and k3s_agent roles
- upload-kubeconfig.sh script extracted from CI workflow
