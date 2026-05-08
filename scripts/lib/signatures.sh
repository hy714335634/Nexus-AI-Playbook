#!/usr/bin/env bash
# Content-hash signatures — skip doc generation when sources unchanged.

# Intentionally NOT setting `set -e` here; sourced by scripts that manage strictness.

if [ -z "${COMMON_SOURCED:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
    COMMON_SOURCED=1
fi

# _sig_path <chapter> <slug>
_sig_path() {
    echo "$SIGNATURES_DIR/${1}__${2}.sha"
}

# _expand_sources — read source patterns from stdin, print absolute matching files
_expand_sources() {
    local src
    src="$(abs_source_repo)"
    python3 "$SCRIPTS_DIR/lib/_expand_sources.py" "$src"
}

# compute_signature <chapter> <slug>
compute_signature() {
    local ch="$1" slug="$2"
    local files
    files="$(doc_sources "$ch" "$slug" | _expand_sources | sort -u)"
    if [ -z "$files" ]; then
        echo "NO_SOURCES"
        return
    fi
    echo "$files" | xargs -I{} sha256sum {} | sort | sha256sum | awk '{print $1}'
}

# load_signature <chapter> <slug>
load_signature() {
    local p
    p="$(_sig_path "$1" "$2")"
    [ -f "$p" ] && cat "$p" || echo ""
}

# save_signature <chapter> <slug> <sig>
save_signature() {
    local p
    p="$(_sig_path "$1" "$2")"
    mkdir -p "$(dirname "$p")"
    echo "$3" > "$p"
}

# signature_matches <chapter> <slug> — exit 0 if stored matches computed, 1 otherwise
signature_matches() {
    local computed stored
    computed="$(compute_signature "$1" "$2")"
    stored="$(load_signature "$1" "$2")"
    [ -n "$stored" ] && [ "$computed" = "$stored" ]
}
