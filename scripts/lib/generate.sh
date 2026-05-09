#!/usr/bin/env bash
# Stage 3: Invoke Claude Code to generate draft docs.
# Reads state/changes.json + state/work/*.
# Writes drafts to drafts/<path>.md and drafts/manual/en/<path>.md.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

command -v claude >/dev/null || die "claude CLI not found in PATH"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json. Run detect+prepare first."

# Resolve model names from config
MODEL_DEFAULT="$(yaml_get '.models.default' | tr -d '"')"
MODEL_COMPLEX="$(yaml_get '.models.complex' | tr -d '"')"

mkdir -p "$DRAFTS_DIR/manual/en" "$DRAFTS_DIR/admin" "$DRAFTS_DIR/guide" "$DRAFTS_DIR/overview"

COUNT="$(jq '.triggered_mappings | length' "$CHANGES_FILE")"
[ "$COUNT" -gt 0 ] || { log "Generate: nothing to do"; exit 0; }

ERROR_LOG="$STATE_DIR/errors.log"
: > "$ERROR_LOG"

for idx in $(seq 0 $((COUNT - 1))); do
    MAP_JSON="$(jq -c ".triggered_mappings[$idx]" "$CHANGES_FILE")"
    MAP_ID="$(echo "$MAP_JSON" | jq -r '.id')"
    WORK="$WORK_DIR/$MAP_ID"

    echo "$MAP_JSON" | jq -c '.docs[]' | while IFS= read -r DOC_JSON; do
        DOC_PATH="$(echo "$DOC_JSON" | jq -r '.path')"
        DOC_SLUG="$(echo "$DOC_PATH" | tr '/' '_' | sed 's/\.md$//')"
        MODEL_KEY="$(echo "$DOC_JSON" | jq -r '.model // "default"')"
        case "$MODEL_KEY" in
            complex) MODEL="$MODEL_COMPLEX" ;;
            *)       MODEL="$MODEL_DEFAULT" ;;
        esac

        # Compute output paths
        EN_PATH="$(echo "$DOC_PATH" | sed 's|^manual/|manual/en/|; s|^guide/|guide/en/|; s|^admin/|admin/en/|; s|^overview/|overview/en/|')"
        OUT_ZH="$DRAFTS_DIR/$DOC_PATH"
        OUT_EN="$DRAFTS_DIR/$EN_PATH"
        mkdir -p "$(dirname "$OUT_ZH")" "$(dirname "$OUT_EN")"

        # Prompt body for this (mapping,doc) pair
        PROMPT_FILE="$WORK/prompt__${DOC_SLUG}.md"
        [ -f "$PROMPT_FILE" ] || { log "Skip: no prompt file $PROMPT_FILE"; continue; }

        log "Generate [$MAP_ID → $DOC_PATH] model=$MODEL"

        # Construct the combined prompt: preamble + template reference + output paths
        COMBINED="$(cat <<EOF
你的工作目录是: $WORK
此次任务的文档 slug: $DOC_SLUG

对应的上下文文件（按 slug 配对）：
  - prompt__${DOC_SLUG}.md  (任务指引 — 请首先完整阅读)
  - current-doc-zh__${DOC_SLUG}.md
  - current-doc-en__${DOC_SLUG}.md
  - changed-files.md (所有变更文件)
  - style-guide.md

输出路径（绝对）：
  OUTPUT_ZH = $OUT_ZH
  OUTPUT_EN = $OUT_EN

请严格按照 prompt__${DOC_SLUG}.md 的指令执行，将最终文档内容写入上述两个绝对路径。
EOF
)"

        # Invoke claude -p; working dir = $WORK for relative Read calls
        if ! (cd "$WORK" && claude -p "$COMBINED" \
                --model "$MODEL" \
                --allowed-tools "Read,Write" \
                --permission-mode "acceptEdits"); then
            echo "[$(date -Iseconds)] FAIL $MAP_ID/$DOC_PATH" >> "$ERROR_LOG"
            log "  FAILED (logged to $ERROR_LOG)"
            continue
        fi

        # Sanity check outputs exist and are non-empty
        if [ ! -s "$OUT_ZH" ]; then
            log "  WARN: $OUT_ZH is empty or missing"
            echo "[$(date -Iseconds)] EMPTY_ZH $MAP_ID/$DOC_PATH" >> "$ERROR_LOG"
        fi
        if [ ! -s "$OUT_EN" ]; then
            log "  WARN: $OUT_EN is empty or missing"
            echo "[$(date -Iseconds)] EMPTY_EN $MAP_ID/$DOC_PATH" >> "$ERROR_LOG"
        fi
    done
done

log "Generate: drafts written to $DRAFTS_DIR"
[ -s "$ERROR_LOG" ] && log "Some errors/warnings; see $ERROR_LOG"
