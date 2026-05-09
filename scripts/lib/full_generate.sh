#!/usr/bin/env bash
# Stage: --full generator.
# Reads state/work-plan.json + config; produces drafts/<chapter>/<slug>.md (zh+en).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$SCRIPTS_DIR/lib/signatures.sh"
source "$SCRIPTS_DIR/lib/audit.sh"

PLAN_FILE="$STATE_DIR/work-plan.json"
[ -f "$PLAN_FILE" ] || die "No work-plan.json. Run resolve.sh first."

CHAPTER="$(jq -r '.chapter' "$PLAN_FILE")"
COMMIT="$(jq -r '.source_commit' "$PLAN_FILE")"
SRC="$(abs_source_repo)"

# Model names
MODEL_DEFAULT="$(yaml_get '.models.default' | tr -d '"')"
MODEL_COMPLEX="$(yaml_get '.models.complex' | tr -d '"')"

DRAFT_BASE="$DRAFTS_DIR/$CHAPTER"
DRAFT_EN="$DRAFTS_DIR/$CHAPTER/en"
mkdir -p "$DRAFT_BASE" "$DRAFT_EN"

# Clean this chapter's work dir (fresh slate per run)
rm -rf "$WORK_DIR/$CHAPTER"
mkdir -p "$WORK_DIR/$CHAPTER"

COUNT_TO_GEN="$(jq '[.items[] | select(.status=="to_generate")] | length' "$PLAN_FILE")"
log "Full-generate chapter=$CHAPTER: $COUNT_TO_GEN doc(s) to generate"

for idx in $(seq 0 $(($(jq '.items | length' "$PLAN_FILE") - 1))); do
    ITEM="$(jq -c ".items[$idx]" "$PLAN_FILE")"
    SLUG="$(echo "$ITEM" | jq -r '.slug')"
    STATUS="$(echo "$ITEM" | jq -r '.status')"
    TITLE_ZH="$(echo "$ITEM" | jq -r '.title_zh')"
    TITLE_EN="$(echo "$ITEM" | jq -r '.title_en')"
    PROMPT_NAME="$(echo "$ITEM" | jq -r '.prompt')"
    MODEL_KEY="$(echo "$ITEM" | jq -r '.model')"

    if [ "$STATUS" = "skip_signature" ]; then
        log "  [$SLUG] skipped (signature match)"
        audit_record_doc "$CHAPTER" "$SLUG" "skipped_signature" 0 0 0 0 ""
        continue
    fi

    # Resolve model
    case "$MODEL_KEY" in
        complex) MODEL="$MODEL_COMPLEX" ;;
        *)       MODEL="$MODEL_DEFAULT" ;;
    esac

    WORK="$WORK_DIR/$CHAPTER/$SLUG"
    mkdir -p "$WORK"

    # Assemble sources.md — use standalone helper to avoid heredoc/stdin trap
    log "  [$SLUG] preparing context"
    {
        echo "# 源代码内容 — $CHAPTER / $SLUG"
        echo
        echo "commit: \`$COMMIT\`"
        echo
        doc_sources "$CHAPTER" "$SLUG" | python3 "$SCRIPTS_DIR/lib/_format_sources.py" "$SRC"
    } > "$WORK/sources.md"

    # Copy existing docs (if present)
    DOC_ZH_PATH="$DOCS_DIR/$CHAPTER/$SLUG.md"
    DOC_EN_PATH="$DOCS_DIR/$CHAPTER/en/$SLUG.md"
    if [ -f "$DOC_ZH_PATH" ]; then
        cp "$DOC_ZH_PATH" "$WORK/current-doc-zh.md"
    else
        echo "(文档不存在)" > "$WORK/current-doc-zh.md"
    fi
    if [ -f "$DOC_EN_PATH" ]; then
        cp "$DOC_EN_PATH" "$WORK/current-doc-en.md"
    else
        echo "(document does not exist yet)" > "$WORK/current-doc-en.md"
    fi

    # Extract HUMAN-EDIT blocks from current docs (if any) for Claude's awareness
    HE_ZH="$(python3 "$SCRIPTS_DIR/lib/human_edit.py" extract "$DOC_ZH_PATH" 2>/dev/null || echo '[]')"
    HE_EN="$(python3 "$SCRIPTS_DIR/lib/human_edit.py" extract "$DOC_EN_PATH" 2>/dev/null || echo '[]')"
    HE_COUNT_ZH="$(echo "$HE_ZH" | jq 'length')"
    HE_COUNT_EN="$(echo "$HE_EN" | jq 'length')"

    # Source files list for frontmatter
    SRC_FILES_JSON="$(doc_sources "$CHAPTER" "$SLUG" | jq -R . | jq -s 'unique')"

    # Build sync-fields.md (reminder for Claude)
    NOW_TS="$(date -u -Iseconds)"
    {
        echo "# frontmatter 的 sync 字段"
        echo
        echo "请将以下字段精确填入生成文档的 frontmatter.sync："
        echo
        echo "- source_commit: \`$COMMIT\`"
        echo "- generated_at: \`$NOW_TS\`"
        echo "- generated_by: docs-sync v2"
        echo "- source_files:"
        echo "$SRC_FILES_JSON" | jq -r '.[]' | sed 's|^|  - |'
    } > "$WORK/sync-fields.md"

    # Copy style-guide and prompt
    cp "$PROMPTS_DIR/style-guide.md" "$WORK/style-guide.md"
    [ -f "$PROMPTS_DIR/$PROMPT_NAME" ] || die "Prompt missing: $PROMPT_NAME"
    cp "$PROMPTS_DIR/$PROMPT_NAME" "$WORK/prompt.md"

    # Output paths
    OUT_ZH="$DRAFT_BASE/$SLUG.md"
    OUT_EN="$DRAFT_EN/$SLUG.md"

    # Pre-frontmatter block
    PRE_FRONTMATTER_ZH="$(cat <<EOF
---
title: $TITLE_ZH
sync:
  source_commit: $COMMIT
  source_files:
$(echo "$SRC_FILES_JSON" | jq -r '.[]' | sed 's|^|    - |')
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"
    PRE_FRONTMATTER_EN="$(cat <<EOF
---
title: $TITLE_EN
sync:
  source_commit: $COMMIT
  source_files:
$(echo "$SRC_FILES_JSON" | jq -r '.[]' | sed 's|^|    - |')
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"

    # Combined invocation prompt
    COMBINED="$(cat <<EOF
工作目录: $WORK
章节: $CHAPTER
文档 slug: $SLUG
中文标题: $TITLE_ZH
英文标题: $TITLE_EN

请按 prompt.md 的说明执行。你需要读取的文件：
  - style-guide.md
  - prompt.md
  - sources.md
  - current-doc-zh.md
  - current-doc-en.md
  - sync-fields.md

输出必须写入以下绝对路径：
  OUTPUT_ZH = $OUT_ZH
  OUTPUT_EN = $OUT_EN

frontmatter 要求你原样使用以下两个预构 frontmatter 块（PRE_FRONTMATTER_ZH / PRE_FRONTMATTER_EN），放在各自文档的最开头：

---PRE_FRONTMATTER_ZH---
$PRE_FRONTMATTER_ZH
---END---

---PRE_FRONTMATTER_EN---
$PRE_FRONTMATTER_EN
---END---

HUMAN-EDIT 块（必须逐字保留在生成的新版中，仅在相应语言版本）：

HUMAN_EDIT_BLOCKS_ZH = $HE_ZH
HUMAN_EDIT_BLOCKS_EN = $HE_EN

完成后打印一行 DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>。
EOF
)"

    START=$SECONDS
    log "  [$SLUG] invoking claude (model=$MODEL)"
    if ! (cd "$WORK" && claude -p "$COMBINED" \
            --model "$MODEL" \
            --allowed-tools "Read,Write" \
            --permission-mode "acceptEdits"); then
        log "  [$SLUG] FAILED"
        audit_record_doc "$CHAPTER" "$SLUG" "failed" 0 0 0 0 "claude -p non-zero"
        continue
    fi
    ELAPSED=$((SECONDS - START))

    # Verify outputs exist and non-empty
    OK=1
    [ -s "$OUT_ZH" ] || OK=0
    [ -s "$OUT_EN" ] || OK=0
    if [ "$OK" = 0 ]; then
        log "  [$SLUG] draft empty or missing"
        audit_record_doc "$CHAPTER" "$SLUG" "empty_output" 0 0 0 0 "draft file empty"
        continue
    fi

    # Verify HUMAN-EDIT preservation (if original existed and had blocks)
    HBP=0
    if [ -f "$DOC_ZH_PATH" ] && [ "$HE_COUNT_ZH" -gt 0 ]; then
        if python3 "$SCRIPTS_DIR/lib/human_edit.py" verify "$DOC_ZH_PATH" "$OUT_ZH" >&2; then
            HBP=$((HBP + HE_COUNT_ZH))
        else
            log "  [$SLUG] HUMAN-EDIT verification FAILED (zh)"
            audit_record_doc "$CHAPTER" "$SLUG" "human_edit_lost" 0 0 0 0 "zh blocks missing"
            continue
        fi
    fi
    if [ -f "$DOC_EN_PATH" ] && [ "$HE_COUNT_EN" -gt 0 ]; then
        if python3 "$SCRIPTS_DIR/lib/human_edit.py" verify "$DOC_EN_PATH" "$OUT_EN" >&2; then
            HBP=$((HBP + HE_COUNT_EN))
        else
            log "  [$SLUG] HUMAN-EDIT verification FAILED (en)"
            audit_record_doc "$CHAPTER" "$SLUG" "human_edit_lost" 0 0 0 0 "en blocks missing"
            continue
        fi
    fi

    # Record success + save signature
    audit_record_doc "$CHAPTER" "$SLUG" "generated" 0 0 0 "$HBP" ""
    save_signature "$CHAPTER" "$SLUG" "$(compute_signature "$CHAPTER" "$SLUG")"
    log "  [$SLUG] generated in ${ELAPSED}s (human_blocks=$HBP)"
done

log "Full-generate: done"
