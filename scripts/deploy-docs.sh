#!/bin/bash
# Deploy Nexus-AI Playbook docs to EC2 via S3 + SSM
# Usage: ./scripts/deploy-docs.sh
#
# Infrastructure:
#   EC2: i-0313506dec0403cc4 (nexus-playbook-docs, us-east-1)
#   ALB: playbook-alb-1119627266.us-east-1.elb.amazonaws.com
#   CloudFront: d2ddmzea82jatm.cloudfront.net (E1AWC624BWTW4J)
#   S3 staging: s3://nexus-playbook-kb-845023/deploy/playbook-docs.tar.gz
set -euo pipefail

REGION="us-east-1"
INSTANCE_ID="i-0313506dec0403cc4"
S3_PATH="s3://nexus-playbook-kb-845023/deploy/playbook-docs.tar.gz"
CF_DIST_ID="E1AWC624BWTW4J"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1/4 Build docs ==="
cd "$PROJECT_DIR"
npm run docs:build

echo "=== 2/4 Upload to S3 ==="
tar -czf /tmp/playbook-docs.tar.gz -C docs/.vitepress/dist .
aws s3 cp /tmp/playbook-docs.tar.gz "$S3_PATH" --region "$REGION"

echo "=== 3/4 Deploy to EC2 via SSM ==="
CMD_ID=$(aws ssm send-command --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --timeout-seconds 120 \
  --parameters 'commands=[
"aws s3 cp '"$S3_PATH"' /tmp/playbook-docs.tar.gz --region '"$REGION"'",
"rm -rf /usr/share/nginx/html/playbook",
"mkdir -p /usr/share/nginx/html/playbook",
"tar -xzf /tmp/playbook-docs.tar.gz -C /usr/share/nginx/html/playbook",
"systemctl restart nginx",
"echo DEPLOY_DONE"
]' \
  --query 'Command.CommandId' --output text)

echo "  SSM Command: $CMD_ID"
echo "  Waiting..."
aws ssm wait command-executed --region "$REGION" \
  --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" 2>/dev/null || true

STATUS=$(aws ssm get-command-invocation --region "$REGION" \
  --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --query 'Status' --output text)

if [ "$STATUS" != "Success" ]; then
  echo "ERROR: SSM command failed (status=$STATUS)"
  aws ssm get-command-invocation --region "$REGION" \
    --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
    --query 'StandardErrorContent' --output text
  exit 1
fi
echo "  EC2 deploy: OK"

echo "=== 4/4 Invalidate CloudFront cache ==="
aws cloudfront create-invalidation --region "$REGION" \
  --distribution-id "$CF_DIST_ID" \
  --paths "/playbook/*" \
  --query 'Invalidation.Id' --output text

echo ""
echo "=== Deploy complete ==="
echo "  ALB:        http://playbook-alb-1119627266.us-east-1.elb.amazonaws.com/playbook/"
echo "  CloudFront: https://d2ddmzea82jatm.cloudfront.net/playbook/"
