#!/usr/bin/env bash
# Stage 0 for --full mode: resolve a chapter (+ optional --doc filter) to a
# concrete work plan at state/work-plan.json.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHAPTER="${1:?chapter required}"
DOC_FILTER="${2:-}"      # optional slug filter
FORCE="${3:-}"           # "force" to ignore signatures

chapter_exists "$CHAPTER" || die "Unknown chapter: $CHAPTER"

source "$SCRIPTS_DIR/lib/signatures.sh"

PLAN_FILE="$STATE_DIR/work-plan.json"
SRC="$(abs_source_repo)"
COMMIT="$(git -C "$SRC" rev-parse HEAD)"

# Start plan
jq -n --arg ch "$CHAPTER" --arg commit "$COMMIT" \
    '{chapter:$ch, source_commit:$commit, items:[]}' > "$PLAN_FILE"

SLUGS="$(chapter_doc_slugs "$CHAPTER")"

while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    if [ -n "$DOC_FILTER" ] && [ "$slug" != "$DOC_FILTER" ]; then
        continue
    fi
    if [ -z "$FORCE" ] && signature_matches "$CHAPTER" "$slug"; then
        STATUS="skip_signature"
    else
        STATUS="to_generate"
    fi
    TITLE_ZH="$(doc_title "$CHAPTER" "$slug" zh)"
    TITLE_EN="$(doc_title "$CHAPTER" "$slug" en)"
    PROMPT="$(yaml_get ".chapters.\"$CHAPTER\".docs[] | select(.slug==\"$slug\") | .prompt // .prompt_default" | tr -d '"')"
    if [ "$PROMPT" = "null" ] || [ -z "$PROMPT" ]; then
        PROMPT="$(chapter_prompt_default "$CHAPTER")"
    fi
    MODEL="$(yaml_get ".chapters.\"$CHAPTER\".docs[] | select(.slug==\"$slug\") | .model // \"default\"" | tr -d '"')"

    jq --arg slug "$slug" --arg status "$STATUS" --arg tz "$TITLE_ZH" --arg te "$TITLE_EN" --arg p "$PROMPT" --arg m "$MODEL" \
       '.items += [{slug:$slug, status:$status, title_zh:$tz, title_en:$te, prompt:$p, model:$m}]' \
       "$PLAN_FILE" > "$PLAN_FILE.tmp" && mv "$PLAN_FILE.tmp" "$PLAN_FILE"
done <<< "$SLUGS"

TOTAL="$(jq '.items | length' "$PLAN_FILE")"
TO_GEN="$(jq '[.items[] | select(.status=="to_generate")] | length' "$PLAN_FILE")"
log "Resolve: chapter=$CHAPTER, total=$TOTAL, to_generate=$TO_GEN"
