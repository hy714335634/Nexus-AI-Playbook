#!/usr/bin/env bash
# Stage 4: optionally run Playwright screenshots. Falls back to TODO list.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json"

ENABLED="$(yaml_get '.screenshots.enabled' | tr -d '"')"
BASE_URL="$(yaml_get '.screenshots.base_url' | tr -d '"')"
OUT_DIR_REL="$(yaml_get '.screenshots.output_dir' | tr -d '"')"
USER="$(yaml_get '.screenshots.login.user' | tr -d '"')"
PASS="$(yaml_get '.screenshots.login.password' | tr -d '"')"

# Resolve output dir relative to scripts/ if relative path given
if [[ "$OUT_DIR_REL" = /* ]]; then
    OUT_DIR_ABS="$OUT_DIR_REL"
else
    OUT_DIR_ABS="$(cd "$SCRIPTS_DIR" && mkdir -p "$OUT_DIR_REL" && cd "$OUT_DIR_REL" && pwd)"
fi
mkdir -p "$DRAFTS_DIR/images-todo"

# Collect all screenshot names across triggered mappings (dedup)
WANTED="$(jq -r '[.triggered_mappings[].screenshots[]] | unique | join(",")' "$CHANGES_FILE")"

if [ -z "$WANTED" ]; then
    log "Screenshot: no screenshots requested"
    exit 0
fi

if [ "$ENABLED" = "never" ]; then
    log "Screenshot: disabled in config"
    {
        echo "# 需要手动截图的条目"
        echo
        echo "截图在 config.yaml 中已禁用。"
        echo
        printf "%s\n" "$WANTED" | tr ',' '\n' | sed 's|^|- [ ] |'
    } > "$DRAFTS_DIR/images-todo/TODO.md"
    exit 0
fi

# Try capture (don't let non-zero exit halt the whole pipeline)
set +e
CAPTURE_OUT="$(node "$SCRIPTS_DIR/screenshots/capture.js" \
    --targets "$WANTED" \
    --base-url "$BASE_URL" \
    --user "$USER" \
    --password "$PASS" \
    --output-dir "$OUT_DIR_ABS" 2>&1)"
CAPTURE_EXIT=$?
set -e

case "$CAPTURE_EXIT" in
    0)
        log "Screenshot: captured successfully"
        echo "$CAPTURE_OUT"
        ;;
    2)
        log "Screenshot: service not running at $BASE_URL — writing TODO list"
        {
            echo "# 需要手动截图的条目"
            echo
            echo "本次服务未运行 (\`$BASE_URL\`)，以下截图未自动生成，请在服务启动后手动补截："
            echo
            printf "%s\n" "$WANTED" | tr ',' '\n' | sed 's|^|- [ ] |'
        } > "$DRAFTS_DIR/images-todo/TODO.md"
        ;;
    *)
        log "Screenshot: failed with exit=$CAPTURE_EXIT"
        echo "$CAPTURE_OUT" | tail -20
        echo "$CAPTURE_OUT" >> "$STATE_DIR/errors.log"
        {
            echo "# 截图失败"
            echo
            echo "Playwright 捕获失败，请查看 \`scripts/state/errors.log\`。"
            echo
            printf "%s\n" "$WANTED" | tr ',' '\n' | sed 's|^|- [ ] |'
        } > "$DRAFTS_DIR/images-todo/TODO.md"
        ;;
esac

exit 0
