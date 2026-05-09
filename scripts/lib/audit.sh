#!/usr/bin/env bash
# Per-run JSON audit logs.

if [ -z "${COMMON_SOURCED:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
    COMMON_SOURCED=1
fi

# Internal helper — path of the current run's JSON
_audit_path() {
    echo "$RUNS_DIR/$(run_id).json"
}

# audit_start <mode> <chapter> <trigger>
audit_start() {
    local mode="$1" chapter="${2:-}" trigger="${3:-cli}"
    local path
    path="$(_audit_path)"
    mkdir -p "$(dirname "$path")"
    local src
    src="$(abs_source_repo)"
    local commit
    commit="$(git -C "$src" rev-parse HEAD 2>/dev/null || echo unknown)"
    jq -n \
        --arg ts "$(date -u -Iseconds)" \
        --arg mode "$mode" \
        --arg chapter "$chapter" \
        --arg trigger "$trigger" \
        --arg commit "$commit" \
        '{timestamp:$ts, mode:$mode, chapter:$chapter, trigger:$trigger, source_commit:$commit, docs:[], total_cost_usd:0, total_elapsed_s:0, exit_code:null}' \
        > "$path"
}

# audit_record_doc <chapter> <slug> <status> [tokens_in] [tokens_out] [cost_usd] [human_blocks_preserved] [error]
audit_record_doc() {
    local ch="$1" slug="$2" status="$3"
    local tokens_in="${4:-0}" tokens_out="${5:-0}" cost="${6:-0}" hbp="${7:-0}" err="${8:-}"
    local path
    path="$(_audit_path)"
    [ -f "$path" ] || return 0
    jq --arg ch "$ch" --arg slug "$slug" --arg status "$status" \
       --argjson ti "$tokens_in" --argjson to "$tokens_out" --argjson cost "$cost" \
       --argjson hbp "$hbp" --arg err "$err" \
       '.docs += [{chapter:$ch, slug:$slug, status:$status, tokens_in:$ti, tokens_out:$to, cost_usd:$cost, human_blocks_preserved:$hbp, error:$err}] | .total_cost_usd = ([.docs[].cost_usd] | add)' \
       "$path" > "$path.tmp" && mv "$path.tmp" "$path"
}

# audit_finish <exit_code>
audit_finish() {
    local code="${1:-0}"
    local path
    path="$(_audit_path)"
    [ -f "$path" ] || return 0
    local start_ts now_ts
    start_ts="$(jq -r '.timestamp' "$path")"
    now_ts="$(date -u -Iseconds)"
    local elapsed
    elapsed="$(python3 -c "from datetime import datetime as d; a=d.fromisoformat('$start_ts'.replace('Z','+00:00')); b=d.fromisoformat('$now_ts'.replace('Z','+00:00')); print(int((b-a).total_seconds()))")"
    jq --arg now "$now_ts" --argjson code "$code" --argjson elapsed "$elapsed" \
       '.finished_at=$now | .exit_code=$code | .total_elapsed_s=$elapsed' \
       "$path" > "$path.tmp" && mv "$path.tmp" "$path"
    log "Audit: $path"
}
