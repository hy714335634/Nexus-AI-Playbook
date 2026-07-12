#!/usr/bin/env bash
# Sync Playbook docs to S3 and manage the Bedrock Knowledge Base ingestion.
#
# Fixed coordinates (created 2026-07-12, account 238090515572 / us-east-1):
#   docs bucket : s3://nexus-playbook-kb-845023/docs/
#   KB          : nexus-playbook-kb  (PB_KB_ID below)
#   data source : s3 (PB_KB_DS_ID below, created by `kb_sync.sh create-ds`)
#   vector store: S3 Vectors bucket nexus-playbook-vectors-845023 / index playbook-docs
#
# Usage: kb_sync.sh sync-s3 | create-ds | ingest | status | query "<question>"
set -euo pipefail

export AWS_REGION="${AWS_REGION:-us-east-1}"
PB_KB_BUCKET="${PB_KB_BUCKET:-nexus-playbook-kb-845023}"
PB_KB_ID="${PB_KB_ID:-ZHIONELMF9}"
PB_KB_DS_ID="${PB_KB_DS_ID:-NCE7NWPIYL}"   # set after create-ds, or pass via env

DOCS_DIR="$(cd "$(dirname "$0")/../../docs" && pwd)"

# resolve data source id if not provided
ds_id() {
    if [ -n "$PB_KB_DS_ID" ]; then echo "$PB_KB_DS_ID"; return; fi
    aws bedrock-agent list-data-sources --knowledge-base-id "$PB_KB_ID" \
        --query 'dataSourceSummaries[0].dataSourceId' --output text
}

case "${1:-}" in
  sync-s3)
    # 只同步正式手册内容（两册 md），排除站点框架与内部文档
    aws s3 sync "$DOCS_DIR/user-guide"  "s3://$PB_KB_BUCKET/docs/user-guide/"  --exclude "*" --include "*.md" --delete
    aws s3 sync "$DOCS_DIR/admin-guide" "s3://$PB_KB_BUCKET/docs/admin-guide/" --exclude "*" --include "*.md" --delete
    aws s3 ls "s3://$PB_KB_BUCKET/docs/" --recursive | wc -l
    ;;
  create-ds)
    aws bedrock-agent create-data-source --knowledge-base-id "$PB_KB_ID" \
      --name s3-docs \
      --data-source-configuration "{\"type\":\"S3\",\"s3Configuration\":{\"bucketArn\":\"arn:aws:s3:::$PB_KB_BUCKET\",\"inclusionPrefixes\":[\"docs/\"]}}" \
      --vector-ingestion-configuration '{"chunkingConfiguration":{"chunkingStrategy":"HIERARCHICAL","hierarchicalChunkingConfiguration":{"levelConfigurations":[{"maxTokens":1500},{"maxTokens":300}],"overlapTokens":60}}}' \
      --query 'dataSource.dataSourceId' --output text
    ;;
  ingest)
    aws bedrock-agent start-ingestion-job --knowledge-base-id "$PB_KB_ID" \
      --data-source-id "$(ds_id)" --query 'ingestionJob.ingestionJobId' --output text
    ;;
  status)
    aws bedrock-agent list-ingestion-jobs --knowledge-base-id "$PB_KB_ID" \
      --data-source-id "$(ds_id)" \
      --query 'ingestionJobSummaries[0].{status:status,stats:statistics}' --output json
    ;;
  query)
    [ -n "${2:-}" ] || { echo "usage: kb_sync.sh query \"<question>\"" >&2; exit 2; }
    aws bedrock-agent-runtime retrieve --knowledge-base-id "$PB_KB_ID" \
      --retrieval-query "{\"text\":\"$2\"}" \
      --retrieval-configuration '{"vectorSearchConfiguration":{"numberOfResults":3}}' \
      --query 'retrievalResults[].{score:score,uri:location.s3Location.uri,text:content.text}' --output json
    ;;
  *) echo "usage: kb_sync.sh sync-s3|create-ds|ingest|status|query" >&2; exit 2;;
esac
