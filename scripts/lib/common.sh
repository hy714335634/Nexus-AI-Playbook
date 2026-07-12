#!/usr/bin/env bash
# Shared helpers sourced by every stage script.
# Defines: SCRIPTS_DIR, REPO_ROOT, CONFIG_FILE, STATE_DIR, DRAFTS_DIR,
#         log(), die(), yaml_get(), abs_source_repo()

set -euo pipefail

# Resolve SCRIPTS_DIR = directory containing this file's parent (lib/..)
COMMON_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$COMMON_SH_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPTS_DIR/config.yaml"
STATE_DIR="$SCRIPTS_DIR/state"
WORK_DIR="$STATE_DIR/work"
DRAFTS_DIR="$REPO_ROOT/drafts"
PROMPTS_DIR="$SCRIPTS_DIR/prompts"

export SCRIPTS_DIR REPO_ROOT CONFIG_FILE STATE_DIR WORK_DIR DRAFTS_DIR PROMPTS_DIR

log() { printf '[%(%H:%M:%S)T] %s\n' -1 "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# yaml_get <jq-expression>  — query config.yaml via python→jq bridge
yaml_get() {
    python3 "$SCRIPTS_DIR/lib/yaml_helper.py" "$CONFIG_FILE" "$1"
}

# abs_source_repo — prints absolute path of Nexus-AI repo
abs_source_repo() {
    local rel
    rel="$(yaml_get '.source_repo.path' | tr -d '"')"
    (cd "$SCRIPTS_DIR" && cd "$rel" && pwd)
}

# ===== v2 additions =====

SIGNATURES_DIR="$STATE_DIR/signatures"
RUNS_DIR="$STATE_DIR/runs"
DOCS_DIR="$REPO_ROOT/docs"
LLMS_TXT_DIR="$REPO_ROOT/docs/public"

export SIGNATURES_DIR RUNS_DIR DOCS_DIR LLMS_TXT_DIR

mkdir -p "$SIGNATURES_DIR" "$RUNS_DIR" 2>/dev/null || true

# run_id — timestamp used for a single sync.sh invocation's audit trail
_RUN_ID=""
run_id() {
    if [ -z "$_RUN_ID" ]; then
        _RUN_ID="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
    fi
    echo "$_RUN_ID"
}

# chapter_doc_slugs <chapter-id> — prints one slug per line for the given chapter
chapter_doc_slugs() {
    local ch="$1"
    yaml_get ".chapters.\"$ch\".docs[].slug" | tr -d '"'
}

# chapter_exists <chapter-id> — exits 0 if yes, 1 if no
chapter_exists() {
    local ch="$1"
    local out
    out="$(yaml_get ".chapters | has(\"$ch\")" 2>/dev/null || true)"
    [ "$out" = "true" ]
}

# doc_sources <chapter-id> <slug> — prints each source pattern on its own line
doc_sources() {
    local ch="$1" slug="$2"
    yaml_get ".chapters.\"$ch\".docs[] | select(.slug==\"$slug\") | .sources[]" | tr -d '"'
}

# doc_title <chapter-id> <slug> <lang>  — lang in {zh,en}
doc_title() {
    local ch="$1" slug="$2" lang="$3"
    yaml_get ".chapters.\"$ch\".docs[] | select(.slug==\"$slug\") | .title_$lang" | tr -d '"'
}

# chapter_title <chapter-id> <lang>
chapter_title() {
    local ch="$1" lang="$2"
    yaml_get ".chapters.\"$ch\".title_$lang" | tr -d '"'
}

# chapter_prompt_default <chapter-id>
chapter_prompt_default() {
    local ch="$1"
    yaml_get ".chapters.\"$ch\".prompt_default" | tr -d '"'
}

# doc_extra_context <chapter-id> <slug> — prints each extra_context path on its own line (empty if field absent)
doc_extra_context() {
    local ch="$1" slug="$2"
    yaml_get ".chapters.\"$ch\".docs[] | select(.slug==\"$slug\") | .extra_context[]? // empty" 2>/dev/null | tr -d '"' || true
}
