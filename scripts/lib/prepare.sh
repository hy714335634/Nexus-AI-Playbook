#!/usr/bin/env bash
# Stage 2: Prepare per-mapping context packs under state/work/<id>/.
# Reads state/changes.json.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json. Run detect first."

SRC="$(abs_source_repo)"
FROM_SHA="$(jq -r '.from_sha' "$CHANGES_FILE")"
TO_SHA="$(jq -r '.to_sha' "$CHANGES_FILE")"

# Clean work dir
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

COUNT="$(jq '.triggered_mappings | length' "$CHANGES_FILE")"
if [ "$COUNT" = "0" ]; then
    log "Prepare: no triggered mappings, nothing to do"
    exit 0
fi

# Iterate over mappings
for idx in $(seq 0 $((COUNT - 1))); do
    MAP_JSON="$(jq -c ".triggered_mappings[$idx]" "$CHANGES_FILE")"
    MAP_ID="$(echo "$MAP_JSON" | jq -r '.id')"
    WORK="$WORK_DIR/$MAP_ID"
    mkdir -p "$WORK"

    log "Prepare [$MAP_ID]"

    # Build changed-files.md
    {
        echo "# 源码变更清单 ($MAP_ID)"
        echo
        echo "Range: \`$FROM_SHA\` → \`$TO_SHA\`"
        echo
        echo "$MAP_JSON" | jq -r '.changed_files[]' | while IFS= read -r f; do
            echo "## $f"
            echo
            echo "### 当前内容"
            echo '```'
            if [ -f "$SRC/$f" ]; then
                cat "$SRC/$f"
            else
                echo "(文件已删除)"
            fi
            echo '```'
            echo
            echo "### Diff vs $FROM_SHA"
            echo '```diff'
            git -C "$SRC" diff "$FROM_SHA" "$TO_SHA" -- "$f" || true
            echo '```'
            echo
        done
    } > "$WORK/changed-files.md"

    # Per-doc context (iterate mapping.docs)
    echo "$MAP_JSON" | jq -c '.docs[]' | while IFS= read -r DOC_JSON; do
        DOC_PATH="$(echo "$DOC_JSON" | jq -r '.path')"
        DOC_SLUG="$(echo "$DOC_PATH" | tr '/' '_' | sed 's/\.md$//')"
        PROMPT_NAME="$(echo "$DOC_JSON" | jq -r '.prompt')"

        # Current zh doc
        if [ -f "$REPO_ROOT/docs/$DOC_PATH" ]; then
            cp "$REPO_ROOT/docs/$DOC_PATH" "$WORK/current-doc-zh__${DOC_SLUG}.md"
        else
            echo "(文档不存在，需全新创建)" > "$WORK/current-doc-zh__${DOC_SLUG}.md"
        fi

        # Current en doc: insert en/ after the first path segment (all v4 chapters)
        EN_PATH="$(echo "$DOC_PATH" | sed 's|^\([^/]*\)/|\1/en/|')"
        if [ -f "$REPO_ROOT/docs/$EN_PATH" ]; then
            cp "$REPO_ROOT/docs/$EN_PATH" "$WORK/current-doc-en__${DOC_SLUG}.md"
        else
            echo "(English version does not exist yet; create from scratch.)" > "$WORK/current-doc-en__${DOC_SLUG}.md"
        fi

        # Copy prompt template
        [ -f "$PROMPTS_DIR/$PROMPT_NAME" ] || die "Prompt not found: $PROMPT_NAME"
        cp "$PROMPTS_DIR/$PROMPT_NAME" "$WORK/prompt__${DOC_SLUG}.md"

        # Extra context (实测走查笔记) — chapter/slug derived from doc path
        EC_CH="$(dirname "$DOC_PATH")"; EC_SLUG="$(basename "$DOC_PATH" .md)"
        EC_OUT="$WORK/extra-context__${DOC_SLUG}.md"
        : > "$EC_OUT"
        while IFS= read -r ec; do
            if [ -n "$ec" ] && [ -f "$REPO_ROOT/$ec" ]; then
                {
                    echo "# EXTRA CONTEXT (实测走查笔记 — 以此为准描述 UI 行为): $ec"
                    cat "$REPO_ROOT/$ec"
                    echo
                } >> "$EC_OUT"
            fi
        done < <(doc_extra_context "$EC_CH" "$EC_SLUG" || true)
        [ -s "$EC_OUT" ] || rm -f "$EC_OUT"
    done

    # Style guide
    [ -f "$PROMPTS_DIR/style-guide.md" ] || die "Missing style-guide.md"
    cp "$PROMPTS_DIR/style-guide.md" "$WORK/style-guide.md"
done

log "Prepare: context packs written to $WORK_DIR"
