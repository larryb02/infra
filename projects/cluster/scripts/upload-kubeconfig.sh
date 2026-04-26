#!/usr/bin/env bash
set -euo pipefail

S3_BUCKET="${S3_BUCKET:-lkb-main-s3-bucket}"
KUBECONFIG_LOCAL="${KUBECONFIG_LOCAL:-/tmp/k3s.yaml}"
S3_KEY="kubeconfig/k3s.yaml"

aws s3 cp "$KUBECONFIG_LOCAL" "s3://${S3_BUCKET}/${S3_KEY}"
echo "Uploaded kubeconfig to s3://${S3_BUCKET}/${S3_KEY}"
