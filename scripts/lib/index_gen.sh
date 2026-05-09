#!/usr/bin/env bash
# Generate <chapter>/index.md (zh+en) from drafts produced by full_generate.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHAPTER="${1:?chapter required}"
chapter_exists "$CHAPTER" || die "Unknown chapter: $CHAPTER"

DRAFT_BASE="$DRAFTS_DIR/$CHAPTER"
DRAFT_EN="$DRAFTS_DIR/$CHAPTER/en"
mkdir -p "$DRAFT_BASE" "$DRAFT_EN"

WORK="$WORK_DIR/$CHAPTER/_index"
mkdir -p "$WORK"

SRC="$(abs_source_repo)"
COMMIT="$(git -C "$SRC" rev-parse HEAD)"
NOW_TS="$(date -u -Iseconds)"

# Build manifest.md listing every slug with its current draft title + first 2 lines of body
{
    echo "# Chapter manifest: $CHAPTER"
    echo
    echo "## Chapter titles"
    echo "- zh: $(chapter_title "$CHAPTER" zh)"
    echo "- en: $(chapter_title "$CHAPTER" en)"
    echo
    echo "## Docs in this chapter"
    while IFS= read -r slug; do
        [ -z "$slug" ] && continue
        TZ="$(doc_title "$CHAPTER" "$slug" zh)"
        TE="$(doc_title "$CHAPTER" "$slug" en)"
        echo
        echo "### $slug"
        echo "- title_zh: $TZ"
        echo "- title_en: $TE"
        echo "- link: ./$slug"
        # Try to include a one-line summary from the draft if it exists
        if [ -f "$DRAFT_BASE/$slug.md" ]; then
            FIRST_PARA="$(awk '/^---$/{c++;next} c==2 && NF{print; exit}' "$DRAFT_BASE/$slug.md" || true)"
            echo "- lead_zh: $FIRST_PARA"
        fi
        if [ -f "$DRAFT_EN/$slug.md" ]; then
            FIRST_PARA_EN="$(awk '/^---$/{c++;next} c==2 && NF{print; exit}' "$DRAFT_EN/$slug.md" || true)"
            echo "- lead_en: $FIRST_PARA_EN"
        fi
    done <<< "$(chapter_doc_slugs "$CHAPTER")"
} > "$WORK/chapter-manifest.md"

# sync-fields.md
{
    echo "# frontmatter 的 sync 字段"
    echo
    echo "source_commit: \`$COMMIT\`"
    echo "generated_at: \`$NOW_TS\`"
    echo "generated_by: docs-sync v2 (index)"
} > "$WORK/sync-fields.md"

cp "$PROMPTS_DIR/style-guide.md" "$WORK/style-guide.md"
cp "$PROMPTS_DIR/chapter-index.md" "$WORK/prompt.md"

OUT_ZH="$DRAFT_BASE/index.md"
OUT_EN="$DRAFT_EN/index.md"

TITLE_ZH="$(chapter_title "$CHAPTER" zh)"
TITLE_EN="$(chapter_title "$CHAPTER" en)"

PRE_FM_ZH="$(cat <<EOF
---
title: $TITLE_ZH
sync:
  source_commit: $COMMIT
  source_files:
    - (chapter index — aggregated)
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"
PRE_FM_EN="$(cat <<EOF
---
title: $TITLE_EN
sync:
  source_commit: $COMMIT
  source_files:
    - (chapter index — aggregated)
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"

MODEL="$(yaml_get '.models.default' | tr -d '"')"

COMBINED="$(cat <<EOF
工作目录: $WORK
章节: $CHAPTER
任务: 生成章节入口页 index.md

阅读 prompt.md 按要求执行。

OUTPUT_ZH = $OUT_ZH
OUTPUT_EN = $OUT_EN

PRE_FRONTMATTER_ZH:
$PRE_FM_ZH

PRE_FRONTMATTER_EN:
$PRE_FM_EN

完成后打印 DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>。
EOF
)"

log "Index gen: chapter=$CHAPTER"
(cd "$WORK" && claude -p "$COMBINED" \
        --model "$MODEL" \
        --allowed-tools "Read,Write" \
        --permission-mode "acceptEdits") || die "Index generation failed"

log "Index: $OUT_ZH + $OUT_EN"
