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
