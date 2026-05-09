#!/usr/bin/env bash
# Stage 5: Write drafts/SUMMARY.md describing what was produced and next steps.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json"

FROM="$(jq -r '.from_sha' "$CHANGES_FILE")"
TO="$(jq -r '.to_sha' "$CHANGES_FILE")"
COUNT="$(jq '.triggered_mappings | length' "$CHANGES_FILE")"

SUMMARY="$DRAFTS_DIR/SUMMARY.md"
mkdir -p "$DRAFTS_DIR"

{
    echo "# 同步摘要 ($(date +%Y-%m-%d))"
    echo
    echo "- From: \`$FROM\`"
    echo "- To:   \`$TO\`"
    echo "- Triggered mappings: $COUNT"
    echo
    echo "## 已生成草稿"
    echo
    if [ "$COUNT" = "0" ]; then
        echo "_无映射触发，无草稿生成。_"
    else
        jq -r '.triggered_mappings[] | "- [ ] `\(.id)` → " + ( [.docs[].path] | join(", ") )' "$CHANGES_FILE"
    fi
    echo
    echo "## 草稿文件"
    echo
    DRAFT_DIRS=()
    for d in manual admin guide overview; do
        [ -d "$DRAFTS_DIR/$d" ] && DRAFT_DIRS+=("$d")
    done
    DRAFT_LIST=""
    if [ ${#DRAFT_DIRS[@]} -gt 0 ]; then
        DRAFT_LIST="$(cd "$DRAFTS_DIR" && find "${DRAFT_DIRS[@]}" -type f -name '*.md' 2>/dev/null | sort | sed 's|^|- |' || true)"
    fi
    if [ -n "$DRAFT_LIST" ]; then
        echo "$DRAFT_LIST"
    else
        echo "_(无)_"
    fi
    echo
    echo "## 截图状态"
    echo
    if [ -f "$DRAFTS_DIR/images-todo/TODO.md" ]; then
        echo "需要手动处理，见 \`drafts/images-todo/TODO.md\`。"
    else
        echo "_全部自动完成或无截图需求。_"
    fi
    echo
    if [ -s "$STATE_DIR/errors.log" ]; then
        echo "## 错误/警告"
        echo
        echo "有错误或警告，详见 \`scripts/state/errors.log\`："
        echo
        echo '```'
        tail -20 "$STATE_DIR/errors.log"
        echo '```'
        echo
    fi
    echo "## 下一步"
    echo
    echo "1. 对比 \`drafts/\` 与 \`docs/\` 的差异。"
    echo "2. 确认无误后，将草稿合并到正式目录（例如 \`cp drafts/manual/xxx.md docs/manual/xxx.md\`）。"
    echo "3. 合并完成后运行 \`./scripts/sync.sh --commit-sync\` 更新 \`last_sync.json\`。"
} > "$SUMMARY"

log "Output: $SUMMARY"
